#!/usr/bin/env bash

set -e
set -o pipefail
set -u

project_id="$PROJECT_ID"
install_id="$INSTALL_ID"
secret_id="grafana-admin-${install_id}"

echo "=========================================="
echo "Grafana Admin Credentials"
echo "=========================================="
echo ""

payload=$(gcloud --project "$project_id" secrets versions access latest --secret="$secret_id")
username=$(echo "$payload" | jq -r '.username')
password=$(echo "$payload" | jq -r '.password')

echo "URL:      https://{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}/grafana"
echo "Username: $username"
echo "Password: $password"
echo ""
echo "=========================================="
