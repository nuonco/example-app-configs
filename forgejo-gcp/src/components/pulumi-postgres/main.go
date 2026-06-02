package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/compute"
	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/servicenetworking"
	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/sql"
	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		projectID := os.Getenv("PROJECT_ID")
		region := os.Getenv("REGION")
		network := os.Getenv("NETWORK")
		tier := os.Getenv("DB_TIER")
		storageRaw := os.Getenv("DB_STORAGE_GB")
		if installID == "" || projectID == "" || region == "" || network == "" || tier == "" || storageRaw == "" {
			return fmt.Errorf("INSTALL_ID, PROJECT_ID, REGION, NETWORK, DB_TIER, DB_STORAGE_GB are required")
		}
		storageGB, err := strconv.Atoi(storageRaw)
		if err != nil {
			return fmt.Errorf("DB_STORAGE_GB must be int: %w", err)
		}

		psaRange, err := compute.NewGlobalAddress(ctx, "forgejo-psa", &compute.GlobalAddressArgs{
			Name:         pulumi.Sprintf("forgejo-psa-%s", installID),
			Project:      pulumi.String(projectID),
			Purpose:      pulumi.String("VPC_PEERING"),
			AddressType:  pulumi.String("INTERNAL"),
			PrefixLength: pulumi.Int(16),
			Network:      pulumi.String(network),
		})
		if err != nil {
			return fmt.Errorf("psa range: %w", err)
		}

		psaConn, err := servicenetworking.NewConnection(ctx, "forgejo-psa", &servicenetworking.ConnectionArgs{
			Network:               pulumi.String(network),
			Service:               pulumi.String("servicenetworking.googleapis.com"),
			ReservedPeeringRanges: pulumi.StringArray{psaRange.Name},
			// A peering connection is per-network and may already exist from a
			// prior partial run; update it instead of failing the create.
			UpdateOnCreationFail: pulumi.Bool(true),
		})
		if err != nil {
			return fmt.Errorf("psa connection: %w", err)
		}

		password, err := random.NewRandomPassword(ctx, "forgejo-db", &random.RandomPasswordArgs{
			Length:          pulumi.Int(32),
			Special:         pulumi.Bool(false),
			OverrideSpecial: pulumi.String(""),
		})
		if err != nil {
			return fmt.Errorf("password: %w", err)
		}

		instance, err := sql.NewDatabaseInstance(ctx, "forgejo", &sql.DatabaseInstanceArgs{
			Name:               pulumi.Sprintf("nuon-forgejo-%s", installID),
			Project:            pulumi.String(projectID),
			Region:             pulumi.String(region),
			DatabaseVersion:    pulumi.String("POSTGRES_16"),
			DeletionProtection: pulumi.Bool(false),
			Settings: &sql.DatabaseInstanceSettingsArgs{
				Edition:          pulumi.String("ENTERPRISE"),
				Tier:             pulumi.String(tier),
				DiskSize:         pulumi.Int(storageGB),
				DiskType:         pulumi.String("PD_SSD"),
				AvailabilityType: pulumi.String("ZONAL"),
				BackupConfiguration: &sql.DatabaseInstanceSettingsBackupConfigurationArgs{
					Enabled:                    pulumi.Bool(true),
					PointInTimeRecoveryEnabled: pulumi.Bool(false),
				},
				IpConfiguration: &sql.DatabaseInstanceSettingsIpConfigurationArgs{
					Ipv4Enabled:    pulumi.Bool(false),
					PrivateNetwork: pulumi.String(network),
				},
				UserLabels: pulumi.StringMap{
					"install-nuon-co-id":     pulumi.String(installID),
					"component-nuon-co-name": pulumi.String("pulumi-postgres"),
				},
			},
		}, pulumi.DependsOn([]pulumi.Resource{psaConn}))
		if err != nil {
			return fmt.Errorf("sql instance: %w", err)
		}

		db, err := sql.NewDatabase(ctx, "forgejo", &sql.DatabaseArgs{
			Name:           pulumi.String("forgejo"),
			Project:        pulumi.String(projectID),
			Instance:       instance.Name,
			DeletionPolicy: pulumi.String("ABANDON"),
		})
		if err != nil {
			return fmt.Errorf("database: %w", err)
		}

		user, err := sql.NewUser(ctx, "forgejo", &sql.UserArgs{
			Name:     pulumi.String("forgejo"),
			Project:  pulumi.String(projectID),
			Instance: instance.Name,
			Password: password.Result,
			// Postgres won't DROP a role that owns objects; abandon on destroy
			// (the instance teardown removes the user anyway).
			DeletionPolicy: pulumi.String("ABANDON"),
		})
		if err != nil {
			return fmt.Errorf("user: %w", err)
		}

		ctx.Export("host", instance.PrivateIpAddress)
		ctx.Export("port", pulumi.String("5432"))
		ctx.Export("database", db.Name)
		ctx.Export("username", user.Name)
		ctx.Export("password", pulumi.ToSecret(password.Result))
		return nil
	})
}
