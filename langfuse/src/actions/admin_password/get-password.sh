#!/usr/bin/env bash

# Prints the headless-init admin credentials for the Langfuse web UI to stdout
# so they show up in the Nuon action output panel. The password lives in the
# langfuse-secrets Kubernetes secret (key: init-user-password), seeded by the
# langfuse_secrets action at install time and consumed by the langfuse-web
# pod via the LANGFUSE_INIT_USER_PASSWORD env var.

set -e
set -o pipefail
set -u

ns="$LANGFUSE_NAMESPACE"
secret_name="$LANGFUSE_SECRET_NAME"
url="$LANGFUSE_URL"
email="$ADMIN_EMAIL"

password=$(kubectl get secret "$secret_name" -n "$ns" -o jsonpath='{.data.init-user-password}' | base64 -d)

if [ -z "$password" ]; then
  echo "ERROR: init-user-password not found in ${ns}/${secret_name}" >&2
  echo "       Make sure the langfuse_secrets action ran successfully." >&2
  exit 1
fi

echo "=========================================="
echo "Langfuse Admin Credentials"
echo "=========================================="
echo ""
echo "Dashboard URL: $url"
echo "Email:         $email"
echo "Password:      $password"
echo ""
echo "=========================================="
