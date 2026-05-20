package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/rds"
	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		vpcID := os.Getenv("VPC_ID")
		subnetsRaw := os.Getenv("PRIVATE_SUBNET_IDS")
		nodeSGID := os.Getenv("NODE_SECURITY_GROUP_ID")
		instanceClass := os.Getenv("DB_INSTANCE_CLASS")
		storageRaw := os.Getenv("DB_STORAGE_GB")
		if installID == "" || vpcID == "" || subnetsRaw == "" || nodeSGID == "" || instanceClass == "" || storageRaw == "" {
			return fmt.Errorf("INSTALL_ID, VPC_ID, PRIVATE_SUBNET_IDS, NODE_SECURITY_GROUP_ID, DB_INSTANCE_CLASS, DB_STORAGE_GB are required")
		}
		storageGB, err := strconv.Atoi(storageRaw)
		if err != nil {
			return fmt.Errorf("DB_STORAGE_GB must be int: %w", err)
		}

		subnetIDs := parseList(subnetsRaw)
		subnetArr := pulumi.StringArray{}
		for _, s := range subnetIDs {
			subnetArr = append(subnetArr, pulumi.String(s))
		}

		tags := pulumi.StringMap{
			"install.nuon.co/id":     pulumi.String(installID),
			"component.nuon.co/name": pulumi.String("pulumi-rds"),
		}

		subnetGroup, err := rds.NewSubnetGroup(ctx, "forgejo", &rds.SubnetGroupArgs{
			Name:      pulumi.String(fmt.Sprintf("nuon-forgejo-%s", installID)),
			SubnetIds: subnetArr,
			Tags:      tags,
		})
		if err != nil {
			return fmt.Errorf("subnet group: %w", err)
		}

		sg, err := ec2.NewSecurityGroup(ctx, "forgejo-rds", &ec2.SecurityGroupArgs{
			Name:        pulumi.String(fmt.Sprintf("nuon-forgejo-rds-%s", installID)),
			Description: pulumi.String("Forgejo RDS Postgres - allow ingress from EKS nodes"),
			VpcId:       pulumi.String(vpcID),
			Tags:        tags,
		})
		if err != nil {
			return fmt.Errorf("sg: %w", err)
		}

		if _, err := ec2.NewSecurityGroupRule(ctx, "forgejo-rds-from-nodes", &ec2.SecurityGroupRuleArgs{
			Type:                  pulumi.String("ingress"),
			FromPort:              pulumi.Int(5432),
			ToPort:                pulumi.Int(5432),
			Protocol:              pulumi.String("tcp"),
			SecurityGroupId:       sg.ID(),
			SourceSecurityGroupId: pulumi.String(nodeSGID),
			Description:           pulumi.String("Postgres from EKS node security group"),
		}); err != nil {
			return fmt.Errorf("ingress rule: %w", err)
		}

		password, err := random.NewRandomPassword(ctx, "forgejo-db", &random.RandomPasswordArgs{
			Length:          pulumi.Int(32),
			Special:         pulumi.Bool(false),
			OverrideSpecial: pulumi.String(""),
		})
		if err != nil {
			return fmt.Errorf("password: %w", err)
		}

		db, err := rds.NewInstance(ctx, "forgejo", &rds.InstanceArgs{
			Identifier:            pulumi.String(fmt.Sprintf("nuon-forgejo-%s", installID)),
			Engine:                pulumi.String("postgres"),
			EngineVersion:         pulumi.String("16.4"),
			InstanceClass:         pulumi.String(instanceClass),
			AllocatedStorage:      pulumi.Int(storageGB),
			StorageType:           pulumi.String("gp3"),
			StorageEncrypted:      pulumi.Bool(true),
			DbName:                pulumi.String("forgejo"),
			Username:              pulumi.String("forgejo"),
			Password:              password.Result,
			DbSubnetGroupName:     subnetGroup.Name,
			VpcSecurityGroupIds:   pulumi.StringArray{sg.ID()},
			PubliclyAccessible:    pulumi.Bool(false),
			SkipFinalSnapshot:     pulumi.Bool(true),
			DeletionProtection:    pulumi.Bool(false),
			BackupRetentionPeriod: pulumi.Int(7),
			ApplyImmediately:      pulumi.Bool(true),
			Tags:                  tags,
		})
		if err != nil {
			return fmt.Errorf("rds instance: %w", err)
		}

		ctx.Export("host", db.Address)
		ctx.Export("port", db.Port)
		ctx.Export("database", db.DbName)
		ctx.Export("username", db.Username)
		ctx.Export("password", pulumi.ToSecret(password.Result))
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
