package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		installID := os.Getenv("INSTALL_ID")
		oidcProvider := os.Getenv("CLUSTER_OIDC_PROVIDER")
		namespace := os.Getenv("NAMESPACE")
		serviceAccount := os.Getenv("SERVICE_ACCOUNT")
		if installID == "" || oidcProvider == "" || namespace == "" || serviceAccount == "" {
			return fmt.Errorf("INSTALL_ID, CLUSTER_OIDC_PROVIDER, NAMESPACE, SERVICE_ACCOUNT are required")
		}

		caller, err := aws.GetCallerIdentity(ctx, nil, nil)
		if err != nil {
			return fmt.Errorf("get caller identity: %w", err)
		}
		accountID := caller.AccountId

		tags := pulumi.StringMap{
			"install.nuon.co/id":     pulumi.String(installID),
			"component.nuon.co/name": pulumi.String("pulumi-s3"),
		}

		bucket, err := s3.NewBucketV2(ctx, "forgejo", &s3.BucketV2Args{
			Bucket:       pulumi.String(fmt.Sprintf("%s-nuon-forgejo", installID)),
			ForceDestroy: pulumi.Bool(true),
			Tags:         tags,
		})
		if err != nil {
			return fmt.Errorf("bucket: %w", err)
		}

		if _, err := s3.NewBucketOwnershipControls(ctx, "forgejo", &s3.BucketOwnershipControlsArgs{
			Bucket: bucket.ID(),
			Rule: &s3.BucketOwnershipControlsRuleArgs{
				ObjectOwnership: pulumi.String("BucketOwnerEnforced"),
			},
		}); err != nil {
			return fmt.Errorf("ownership: %w", err)
		}

		if _, err := s3.NewBucketServerSideEncryptionConfigurationV2(ctx, "forgejo", &s3.BucketServerSideEncryptionConfigurationV2Args{
			Bucket: bucket.ID(),
			Rules: s3.BucketServerSideEncryptionConfigurationV2RuleArray{
				&s3.BucketServerSideEncryptionConfigurationV2RuleArgs{
					ApplyServerSideEncryptionByDefault: &s3.BucketServerSideEncryptionConfigurationV2RuleApplyServerSideEncryptionByDefaultArgs{
						SseAlgorithm: pulumi.String("AES256"),
					},
				},
			},
		}); err != nil {
			return fmt.Errorf("sse: %w", err)
		}

		if _, err := s3.NewBucketPublicAccessBlock(ctx, "forgejo", &s3.BucketPublicAccessBlockArgs{
			Bucket:                bucket.ID(),
			BlockPublicAcls:       pulumi.Bool(true),
			BlockPublicPolicy:     pulumi.Bool(true),
			IgnorePublicAcls:      pulumi.Bool(true),
			RestrictPublicBuckets: pulumi.Bool(true),
		}); err != nil {
			return fmt.Errorf("public access block: %w", err)
		}

		trustPolicy, err := json.Marshal(map[string]any{
			"Version": "2012-10-17",
			"Statement": []any{
				map[string]any{
					"Effect":    "Allow",
					"Principal": map[string]any{"Federated": fmt.Sprintf("arn:aws:iam::%s:oidc-provider/%s", accountID, oidcProvider)},
					"Action":    "sts:AssumeRoleWithWebIdentity",
					"Condition": map[string]any{
						"StringEquals": map[string]any{
							fmt.Sprintf("%s:aud", oidcProvider): "sts.amazonaws.com",
							fmt.Sprintf("%s:sub", oidcProvider): fmt.Sprintf("system:serviceaccount:%s:%s", namespace, serviceAccount),
						},
					},
				},
			},
		})
		if err != nil {
			return fmt.Errorf("marshal trust policy: %w", err)
		}

		role, err := iam.NewRole(ctx, "forgejo", &iam.RoleArgs{
			Name:             pulumi.String(fmt.Sprintf("%s-nuon-forgejo-role", installID)),
			AssumeRolePolicy: pulumi.String(string(trustPolicy)),
			Tags:             tags,
		})
		if err != nil {
			return fmt.Errorf("role: %w", err)
		}

		bucketPolicy := pulumi.All(bucket.Arn, pulumi.Sprintf("%s/*", bucket.Arn)).ApplyT(func(args []any) (string, error) {
			doc, err := json.Marshal(map[string]any{
				"Version": "2012-10-17",
				"Statement": []any{
					map[string]any{
						"Effect":   "Allow",
						"Action":   []string{"s3:ListBucket", "s3:GetBucketLocation"},
						"Resource": args[0],
					},
					map[string]any{
						"Effect":   "Allow",
						"Action":   []string{"s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"},
						"Resource": args[1],
					},
				},
			})
			return string(doc), err
		}).(pulumi.StringOutput)

		if _, err := iam.NewRolePolicy(ctx, "forgejo-bucket-access", &iam.RolePolicyArgs{
			Role:   role.Name,
			Policy: bucketPolicy,
		}); err != nil {
			return fmt.Errorf("role policy: %w", err)
		}

		ctx.Export("bucket_name", bucket.Bucket)
		ctx.Export("bucket_region", bucket.Region)
		ctx.Export("role_arn", role.Arn)
		return nil
	})
}
