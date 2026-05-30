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

echo "[demo] installing python deps (langfuse, anthropic)"
# Nuon runner's Python 3 may not ship with pip pre-installed (we hit
# "/usr/bin/python3: No module named pip" on first try). Bootstrap pip
# via ensurepip — built into Python's stdlib since 3.4 and works
# offline (uses a bundled wheel). Falls back to get-pip.py over HTTP
# if ensurepip isn't available either.
if ! python3 -m pip --version >/dev/null 2>&1; then
  echo "[demo] pip not found; bootstrapping via ensurepip"
  if ! python3 -m ensurepip --user --upgrade 2>/dev/null; then
    echo "[demo] ensurepip unavailable; falling back to get-pip.py"
    curl -sSL https://bootstrap.pypa.io/get-pip.py | python3 - --user
  fi
fi
python3 -m pip install --quiet --user --disable-pip-version-check langfuse anthropic

echo "[demo] running agent against ${LANGFUSE_HOST}"
python3 "$(dirname "$0")/agent.py"

echo
echo "[demo] done — open ${LANGFUSE_HOST} and sign in as admin@langfuse.local"
echo "[demo] the admin password is in: kubectl get secret -n ${LANGFUSE_NAMESPACE} ${LANGFUSE_SECRET_NAME} -o jsonpath='{.data.init-user-password}' | base64 -d"
