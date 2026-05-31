#!/usr/bin/env bash

# Sends a single user-supplied prompt to Claude and emits a Langfuse trace
# of the call (input, output, model, token usage, cost). Operator picks the
# prompt at run time via the PROMPT env var in the Nuon dashboard's run
# dialog. Useful for ad-hoc smoke-testing the install with realistic inputs.

set -e
set -o pipefail
set -u

# Anthropic API key lives in AWS Secrets Manager (see secrets.toml) — fetch
# the SecretString at run time via the install_stack-exposed ARN.
if [ -z "${ANTHROPIC_SECRET_ARN:-}" ]; then
  echo "[prompt] anthropic_api_key secret not set on this install." >&2
  echo "[prompt] Apply the install stack with an Anthropic API key value in the CFN parameter, then re-run." >&2
  exit 1
fi
echo "[prompt] fetching Anthropic API key from Secrets Manager"
ANTHROPIC_API_KEY=$(aws --region "$REGION" secretsmanager get-secret-value \
  --secret-id "$ANTHROPIC_SECRET_ARN" --query SecretString --output text)
export ANTHROPIC_API_KEY
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "[prompt] Secrets Manager returned an empty value for $ANTHROPIC_SECRET_ARN." >&2
  echo "[prompt] Update the install stack with a non-empty Anthropic API key." >&2
  exit 1
fi

if [ -z "${PROMPT:-}" ]; then
  echo "[prompt] PROMPT env var is empty." >&2
  echo "[prompt] Edit the PROMPT field in the run-action dialog before clicking Run." >&2
  exit 1
fi

echo "[prompt] reading bootstrap keys from ${LANGFUSE_NAMESPACE}/${LANGFUSE_SECRET_NAME}"
LANGFUSE_PUBLIC_KEY=$(kubectl get secret "$LANGFUSE_SECRET_NAME" -n "$LANGFUSE_NAMESPACE" -o jsonpath='{.data.init-public-key}' | base64 -d)
LANGFUSE_SECRET_KEY=$(kubectl get secret "$LANGFUSE_SECRET_NAME" -n "$LANGFUSE_NAMESPACE" -o jsonpath='{.data.init-secret-key}' | base64 -d)
export LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY

if [ -z "$LANGFUSE_PUBLIC_KEY" ] || [ -z "$LANGFUSE_SECRET_KEY" ]; then
  echo "[prompt] init keys not found in ${LANGFUSE_NAMESPACE}/${LANGFUSE_SECRET_NAME}" >&2
  exit 1
fi

# Nuon runner's Python 3 is PEP 668 externally-managed, so use a venv —
# pip-installs inside the venv are exempt from the system-wide restriction.
VENV_DIR="/tmp/run-agent-prompt-venv"
echo "[prompt] creating isolated python venv for deps"
python3 -m venv "$VENV_DIR"

echo "[prompt] installing python deps (langfuse<3, anthropic) into venv"
# Pin langfuse to 2.x — v3 dropped langfuse.decorators which agent.py
# imports. Worth a follow-up to rewrite for the v3 API.
"$VENV_DIR/bin/pip" install --quiet --disable-pip-version-check "langfuse>=2,<3" anthropic

echo "[prompt] sending prompt to ${CLAUDE_MODEL:-claude-sonnet-4-6} via ${LANGFUSE_HOST}"
"$VENV_DIR/bin/python" "$(dirname "$0")/agent.py"
