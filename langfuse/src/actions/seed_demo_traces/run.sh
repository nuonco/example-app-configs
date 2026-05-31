#!/usr/bin/env bash

# Runs a small tool-using Claude agent against this install's Langfuse and
# seeds a real trace tree so the customer can see Langfuse working end to end.

set -e
set -o pipefail
set -u

# Anthropic API key lives in AWS Secrets Manager (see secrets.toml) — the
# install stack's CFN parameter writes the value there and exposes the ARN
# as an output. Fetch the SecretString at run time so the plaintext never
# touches the Nuon control plane or the runner pod's env.
if [ -z "${ANTHROPIC_SECRET_ARN:-}" ]; then
  echo "[demo] anthropic_api_key secret not set on this install." >&2
  echo "[demo] Apply the install stack with an Anthropic API key value in the CFN parameter, then re-run." >&2
  exit 1
fi
echo "[demo] fetching Anthropic API key from Secrets Manager"
ANTHROPIC_API_KEY=$(aws --region "$REGION" secretsmanager get-secret-value \
  --secret-id "$ANTHROPIC_SECRET_ARN" --query SecretString --output text)
export ANTHROPIC_API_KEY
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "[demo] Secrets Manager returned an empty value for $ANTHROPIC_SECRET_ARN." >&2
  echo "[demo] Update the install stack with a non-empty Anthropic API key." >&2
  exit 1
fi

echo "[demo] reading bootstrap keys from ${LANGFUSE_NAMESPACE}/${LANGFUSE_SECRET_NAME}"
LANGFUSE_PUBLIC_KEY=$(kubectl get secret "$LANGFUSE_SECRET_NAME" -n "$LANGFUSE_NAMESPACE" -o jsonpath='{.data.init-public-key}' | base64 -d)
LANGFUSE_SECRET_KEY=$(kubectl get secret "$LANGFUSE_SECRET_NAME" -n "$LANGFUSE_NAMESPACE" -o jsonpath='{.data.init-secret-key}' | base64 -d)
export LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY

if [ -z "$LANGFUSE_PUBLIC_KEY" ] || [ -z "$LANGFUSE_SECRET_KEY" ]; then
  echo "[demo] init keys not found in ${LANGFUSE_NAMESPACE}/${LANGFUSE_SECRET_NAME}" >&2
  exit 1
fi

echo "[demo] creating isolated python venv for deps"
# Nuon runner's system Python is marked PEP 668 "externally-managed-environment"
# (we hit "error: externally-managed-environment" trying to pip install at the
# user level, and even bootstrapping pip via get-pip.py fails). venv is
# explicitly exempt from PEP 668 — packages installed inside the venv don't
# touch the system site-packages, so pip works normally there.
VENV_DIR="/tmp/seed-demo-traces-venv"
python3 -m venv "$VENV_DIR"

echo "[demo] installing python deps (langfuse<3, anthropic) into venv"
# Pin to langfuse 2.x — v3 restructured the SDK and removed
# langfuse.decorators (where @observe and langfuse_context live).
# agent.py uses the v2 decorator pattern; bump to v3 + rewrite later.
"$VENV_DIR/bin/pip" install --quiet --disable-pip-version-check "langfuse>=2,<3" anthropic

echo "[demo] running agent against ${LANGFUSE_HOST}"
"$VENV_DIR/bin/python" "$(dirname "$0")/agent.py"

echo
echo "[demo] done — open ${LANGFUSE_HOST} and sign in as admin@langfuse.local"
echo "[demo] the admin password is in: kubectl get secret -n ${LANGFUSE_NAMESPACE} ${LANGFUSE_SECRET_NAME} -o jsonpath='{.data.init-user-password}' | base64 -d"
