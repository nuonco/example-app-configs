package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/redis"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		projectID := os.Getenv("PROJECT_ID")
		region := os.Getenv("REGION")
		network := os.Getenv("NETWORK")
		memoryRaw := os.Getenv("REDIS_MEMORY_GB")
		if installID == "" || projectID == "" || region == "" || network == "" || memoryRaw == "" {
			return fmt.Errorf("INSTALL_ID, PROJECT_ID, REGION, NETWORK, REDIS_MEMORY_GB are required")
		}
		memoryGB, err := strconv.Atoi(memoryRaw)
		if err != nil {
			return fmt.Errorf("REDIS_MEMORY_GB must be int: %w", err)
		}

		instance, err := redis.NewInstance(ctx, "forgejo", &redis.InstanceArgs{
			Name:                  pulumi.Sprintf("nuon-forgejo-%s", installID),
			Project:               pulumi.String(projectID),
			Region:                pulumi.String(region),
			Tier:                  pulumi.String("BASIC"),
			MemorySizeGb:          pulumi.Int(memoryGB),
			RedisVersion:          pulumi.String("REDIS_7_2"),
			AuthorizedNetwork:     pulumi.String(network),
			ConnectMode:           pulumi.String("DIRECT_PEERING"),
			TransitEncryptionMode: pulumi.String("DISABLED"),
			Labels: pulumi.StringMap{
				"install-nuon-co-id":     pulumi.String(installID),
				"component-nuon-co-name": pulumi.String("pulumi-redis"),
			},
		})
		if err != nil {
			return fmt.Errorf("redis: %w", err)
		}

		ctx.Export("host", instance.Host)
		ctx.Export("port", instance.Port)
		return nil
	})
}
