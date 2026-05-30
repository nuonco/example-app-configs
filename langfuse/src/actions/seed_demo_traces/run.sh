#!/usr/bin/env bash

# Runs a small tool-using Claude agent against this install's Langfuse and
# seeds a real trace tree so the customer can see Langfuse working end to end.

set -e
set -o pipefail
set -u

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "[demo] ANTHROPIC_API_KEY input is empty." >&2
  echo "[demo] Set the 'anthropic_api_key' input on the install and re-run this action." >&2
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
