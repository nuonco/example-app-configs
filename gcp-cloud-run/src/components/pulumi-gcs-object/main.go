package main

import (
	"fmt"
	"os"

	"github.com/pulumi/pulumi-gcp/sdk/v8/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		bucketName := os.Getenv("BUCKET_NAME")

		if bucketName == "" {
			return fmt.Errorf("BUCKET_NAME env var is required (should come from pulumi_gcs_bucket outputs)")
		}

		obj, err := storage.NewBucketObject(ctx, "nuon-metadata", &storage.BucketObjectArgs{
			Bucket:  pulumi.String(bucketName),
			Name:    pulumi.Sprintf("nuon-metadata/%s.json", installID),
			Content: pulumi.Sprintf(`{"install_id": "%s", "managed_by": "nuon"}`, installID),
		})
		if err != nil {
			return fmt.Errorf("error creating bucket object: %w", err)
		}

		ctx.Export("object_name", obj.Name)
		ctx.Export("object_url", pulumi.Sprintf("gs://%s/%s", bucketName, obj.Name))
		ctx.Export("bucket_name", pulumi.String(bucketName))

		return nil
	})
}
