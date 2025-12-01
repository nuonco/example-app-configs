#!/usr/bin/env bash

set -e
set -o pipefail
set -u


# re-assigning these vars so the script fails early if any are missing
address="$DB_HOST"
port="$DB_PORT"
secret_arn="$DB_SECRET_ARN"
install_id="$NUON_INSTALL_ID"
region="$REGION"
version="1.26.2"
cluster_name="$CLUSTER_NAME"

echo "[temporal init] kubectl auth whoami"
echo "pwd: "`pwd`
kubectl auth whoami -o json | jq -c

# set later
user="nuonadmin i think"
password="wouldn't you like to know ... "

echo "[temporal init] reading db access secrets from AWS"
secret=`aws --region $region secretsmanager get-secret-value --secret-id=$secret_arn`
username=`echo $secret | jq -r '.SecretString' | jq -r '.username'`
password=`echo $secret | jq -r '.SecretString' | jq -r '.password'`


# TODO: re-write this so we can see the logs - maybe use exec
kubectl       \
  run         \
  -i          \
  --rm        \
  --tty=false \
  --restart=Never      \
  --namespace=temporal \
  "nuon-temporal-admintools-$(date +"%s")-$(openssl rand -hex 4)"  \
  --image=temporalio/admin-tools:"$version" \
  --env="SQL_HOST=$address"      \
  --env="SQL_PORT=$port"         \
  --env="SQL_USER=$username"     \
  --env="SQL_PASSWORD=$password" \
  --env="SQL_PLUGIN=postgres12"  \
  --env="VERSION=$version"       \
  --command \
  -- bash -c "temporal-sql-tool --db temporal create;  temporal-sql-tool --db temporal setup-schema -v 0.0; temporal-sql-tool --db temporal update-schema -d ./schema/postgresql/v12/temporal/versioned/; temporal-sql-tool --db temporal_visibility create; temporal-sql-tool --db temporal_visibility setup-schema -v 0.0; temporal-sql-tool --db temporal_visibility update-schema -d ./schema/postgresql/v12/temporal/versioned/;"
