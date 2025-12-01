#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
secret_arn="$SECRET_ARN"
name="$TARGET_NAME"
namespace="$TARGET_NAMESPACE"

echo "[rds-secrets import] kubectl auth whoami"
echo "pwd: "`pwd`
kubectl auth whoami -o json | jq -c

echo "[rds-secrets import] reading db access secrets from AWS"
secret=`aws --region $region secretsmanager get-secret-value --secret-id=$secret_arn`
username=`echo $secret | jq -r '.SecretString' | jq -r '.username'`
password=`echo $secret | jq -r '.SecretString' | jq -r '.password'`

echo "[rds-secrets import] create RDS access secrets"
kubectl create -n $namespace secret generic $name \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  -o yaml | kubectl apply -f -
