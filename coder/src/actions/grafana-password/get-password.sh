#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
install_id="$INSTALL_ID"
secret_name="grafana-admin-${install_id}"

echo "=========================================="
echo "Grafana Admin Credentials"
echo "=========================================="
echo ""

secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$secret_name")
username=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

echo "URL:      https://grafana.{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}"
echo "Username: $username"
echo "Password: $password"
echo ""
echo "=========================================="
