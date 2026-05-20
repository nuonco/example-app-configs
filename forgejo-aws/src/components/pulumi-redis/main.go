package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/elasticache"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		vpcID := os.Getenv("VPC_ID")
		subnetsRaw := os.Getenv("PRIVATE_SUBNET_IDS")
		nodeSGID := os.Getenv("NODE_SECURITY_GROUP_ID")
		nodeType := os.Getenv("REDIS_NODE_TYPE")
		if installID == "" || vpcID == "" || subnetsRaw == "" || nodeSGID == "" || nodeType == "" {
			return fmt.Errorf("INSTALL_ID, VPC_ID, PRIVATE_SUBNET_IDS, NODE_SECURITY_GROUP_ID, REDIS_NODE_TYPE are required")
		}

		subnetIDs := parseList(subnetsRaw)
		subnetArr := pulumi.StringArray{}
		for _, s := range subnetIDs {
			subnetArr = append(subnetArr, pulumi.String(s))
		}

		tags := pulumi.StringMap{
			"install.nuon.co/id":     pulumi.String(installID),
			"component.nuon.co/name": pulumi.String("pulumi-redis"),
		}

		subnetGroup, err := elasticache.NewSubnetGroup(ctx, "forgejo", &elasticache.SubnetGroupArgs{
			Name:      pulumi.String(fmt.Sprintf("nuon-forgejo-%s", installID)),
			SubnetIds: subnetArr,
			Tags:      tags,
		})
		if err != nil {
			return fmt.Errorf("subnet group: %w", err)
		}

		sg, err := ec2.NewSecurityGroup(ctx, "forgejo-redis", &ec2.SecurityGroupArgs{
			Name:        pulumi.String(fmt.Sprintf("nuon-forgejo-redis-%s", installID)),
			Description: pulumi.String("Forgejo ElastiCache Redis - allow ingress from EKS nodes"),
			VpcId:       pulumi.String(vpcID),
			Tags:        tags,
		})
		if err != nil {
			return fmt.Errorf("sg: %w", err)
		}

		if _, err := ec2.NewSecurityGroupRule(ctx, "forgejo-redis-from-nodes", &ec2.SecurityGroupRuleArgs{
			Type:                  pulumi.String("ingress"),
			FromPort:              pulumi.Int(6379),
			ToPort:                pulumi.Int(6379),
			Protocol:              pulumi.String("tcp"),
			SecurityGroupId:       sg.ID(),
			SourceSecurityGroupId: pulumi.String(nodeSGID),
			Description:           pulumi.String("Redis from EKS node security group"),
		}); err != nil {
			return fmt.Errorf("ingress rule: %w", err)
		}

		cluster, err := elasticache.NewCluster(ctx, "forgejo", &elasticache.ClusterArgs{
			ClusterId:          pulumi.String(fmt.Sprintf("nuon-forgejo-%s", installID)),
			Engine:             pulumi.String("redis"),
			EngineVersion:      pulumi.String("7.1"),
			NodeType:           pulumi.String(nodeType),
			NumCacheNodes:      pulumi.Int(1),
			ParameterGroupName: pulumi.String("default.redis7"),
			Port:               pulumi.Int(6379),
			SubnetGroupName:    subnetGroup.Name,
			SecurityGroupIds:   pulumi.StringArray{sg.ID()},
			Tags:               tags,
		})
		if err != nil {
			return fmt.Errorf("cluster: %w", err)
		}

		primary := cluster.CacheNodes.Index(pulumi.Int(0))
		ctx.Export("host", primary.Address())
		ctx.Export("port", primary.Port())
		return nil
	})
}

func parseList(s string) []string {
	s = strings.TrimSpace(s)
	s = strings.TrimPrefix(s, "[")
	s = strings.TrimSuffix(s, "]")
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		p = strings.Trim(p, `"`)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}
