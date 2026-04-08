package main

import (
	"fmt"
	"os"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")

		bucket, err := s3.NewBucketV2(ctx, "nuon-bucket", &s3.BucketV2Args{
			Bucket: pulumi.Sprintf("nuon-pulumi-%s", installID),
			Tags: pulumi.StringMap{
				"ManagedBy": pulumi.String("nuon"),
				"InstallID": pulumi.String(installID),
			},
		})
		if err != nil {
			return fmt.Errorf("error creating bucket: %w", err)
		}

		ctx.Export("bucket_name", bucket.Bucket)
		ctx.Export("bucket_arn", bucket.Arn)

		return nil
	})
}
