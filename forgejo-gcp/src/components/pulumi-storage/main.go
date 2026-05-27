package main

import (
	"fmt"
	"os"

	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/projects"
	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/serviceaccount"
	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		projectID := os.Getenv("PROJECT_ID")
		region := os.Getenv("REGION")
		if installID == "" || projectID == "" || region == "" {
			return fmt.Errorf("INSTALL_ID, PROJECT_ID, REGION are required")
		}

		labels := pulumi.StringMap{
			"install-nuon-co-id":     pulumi.String(installID),
			"component-nuon-co-name": pulumi.String("pulumi-storage"),
		}

		bucket, err := storage.NewBucket(ctx, "forgejo", &storage.BucketArgs{
			Name:                     pulumi.Sprintf("%s-nuon-forgejo", installID),
			Location:                 pulumi.String(region),
			ForceDestroy:             pulumi.Bool(true),
			UniformBucketLevelAccess: pulumi.Bool(true),
			Labels:                   labels,
		})
		if err != nil {
			return fmt.Errorf("bucket: %w", err)
		}

		sa, err := serviceaccount.NewAccount(ctx, "forgejo-storage", &serviceaccount.AccountArgs{
			AccountId:   pulumi.Sprintf("forgejo-%s", installID),
			DisplayName: pulumi.String("Forgejo S3-interop access"),
			Project:     pulumi.String(projectID),
		})
		if err != nil {
			return fmt.Errorf("service account: %w", err)
		}

		if _, err := storage.NewBucketIAMMember(ctx, "forgejo-storage", &storage.BucketIAMMemberArgs{
			Bucket: bucket.Name,
			Role:   pulumi.String("roles/storage.objectAdmin"),
			Member: pulumi.Sprintf("serviceAccount:%s", sa.Email),
		}); err != nil {
			return fmt.Errorf("bucket iam: %w", err)
		}

		if _, err := projects.NewIAMMember(ctx, "forgejo-storage-list", &projects.IAMMemberArgs{
			Project: pulumi.String(projectID),
			Role:    pulumi.String("roles/storage.objectViewer"),
			Member:  pulumi.Sprintf("serviceAccount:%s", sa.Email),
		}); err != nil {
			return fmt.Errorf("project iam: %w", err)
		}

		hmac, err := storage.NewHmacKey(ctx, "forgejo-storage", &storage.HmacKeyArgs{
			ServiceAccountEmail: sa.Email,
			Project:             pulumi.String(projectID),
		})
		if err != nil {
			return fmt.Errorf("hmac: %w", err)
		}

		ctx.Export("bucket_name", bucket.Name)
		ctx.Export("bucket_region", bucket.Location)
		ctx.Export("service_account_email", sa.Email)
		ctx.Export("hmac_access_id", hmac.AccessId)
		ctx.Export("hmac_secret", pulumi.ToSecret(hmac.Secret))
		return nil
	})
}
