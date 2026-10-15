#!/usr/bin/env bash

set -e
set -o pipefail
set -u

if [[ "${1:-}" != "" && "${1:-}" != -* ]]; then
  INSTALL_ID="$1"
  shift
fi
: "${INSTALL_ID:?set INSTALL_ID or pass the Nuon install ID as the first argument}"
if [[ $# -gt 0 ]]; then
  printf 'unexpected argument: %s\n' "$1" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="$script_dir/../install-stack/install.auto.tfvars"
inputs_json="$(mktemp)"
install_json="$(mktemp)"
stack_json="$(mktemp)"
trap 'rm -f "$inputs_json" "$install_json" "$stack_json"' EXIT

# The CLI reads NUON_CONFIG_FILE / -C, not NUON_CONFIG. Map the name people set.
nuon_config="${NUON_CONFIG:-${NUON_CONFIG_FILE:-}}"
nuon=(nuon)
if [[ -n "$nuon_config" ]]; then
  nuon+=(-C "$nuon_config")
fi

"${nuon[@]}" api "/v1/installs/$INSTALL_ID" --raw >"$install_json"
"${nuon[@]}" api "/v1/installs/$INSTALL_ID/inputs" --raw >"$inputs_json"
"${nuon[@]}" api "/v1/installs/$INSTALL_ID/stack" --raw >"$stack_json"

require_install_string() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    printf 'error: install %s has no %s\n' "$INSTALL_ID" "$name" >&2
    exit 1
  fi
}

nuon_install_id="$(jq -r '.id // ""' "$install_json")"
nuon_org_id="$(jq -r '.org_id // ""' "$install_json")"
nuon_app_id="$(jq -r '.app_id // ""' "$install_json")"
aws_region="$(jq -r '.aws_account.region // ""' "$install_json")"
runner_id="$(jq -r '.runner_id // ""' "$install_json")"
require_install_string id "$nuon_install_id"
require_install_string org_id "$nuon_org_id"
require_install_string app_id "$nuon_app_id"
require_install_string aws_account.region "$aws_region"
require_install_string runner_id "$runner_id"

phone_home_url="$(jq -r '.versions[0].phone_home_url // ""' "$stack_json")"
if [[ -z "$phone_home_url" ]]; then
  printf 'error: install %s stack has no phone_home_url\n' "$INSTALL_ID" >&2
  exit 1
fi

# Rendered into the latest stack version, not onto the install itself.
stack_inputs="$(
  jq -er '
    def envelope:
      if . == null or . == "" then error("missing terraform_contents")
      elif type == "string" then (. | @base64d | fromjson)
      elif type == "object" then .
      else error("unexpected terraform_contents")
      end;
    .versions[0].terraform_contents
    | envelope
    | .inputs_tfvars
    | {
        nuon_support_iam_role_arns: (
          capture("(?m)^nuon_support_iam_role_arns\\s*=\\s*(?<v>\\[[^\\]]*\\])") | .v | fromjson
        ),
        runner_api_url: (
          capture("(?m)^runner_api_url\\s*=\\s*\"(?<v>[^\"]+)\"") | .v
        )
      }
  ' "$stack_json"
)" || {
  printf 'error: install %s stack is missing nuon_support_iam_role_arns or runner_api_url\n' "$INSTALL_ID" >&2
  exit 1
}
nuon_support_iam_role_arns="$(jq -c '.nuon_support_iam_role_arns' <<<"$stack_inputs")"
runner_api_url="$(jq -r '.runner_api_url' <<<"$stack_inputs")"

values="$(jq -er 'sort_by(.created_at) | last | .values | select(type == "object")' "$inputs_json")"

for key in cluster_name namespaces; do
  val="$(jq -er --arg k "$key" '.[$k] // ""' <<<"$values")"
  val="$(printf '%s' "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ -z "$val" ]]; then
    printf 'Install %s has no %s input. Set it before generating inputs.\n' "$INSTALL_ID" "$key" >&2
    exit 1
  fi
done

jq -er \
  --arg install_id "$INSTALL_ID" \
  --arg nuon_install_id "$nuon_install_id" \
  --arg nuon_org_id "$nuon_org_id" \
  --arg nuon_app_id "$nuon_app_id" \
  --argjson nuon_support_iam_role_arns "$nuon_support_iam_role_arns" \
  --arg aws_region "$aws_region" \
  --arg runner_id "$runner_id" \
  --arg runner_api_url "$runner_api_url" \
  --arg phone_home_url "$phone_home_url" '
  to_entries
  | sort_by(.key)
  | map("  \(.key | @json) = \(.value | tostring | gsub("^\\s+|\\s+$"; "") | @json)")
  | "# Generated from install \($install_id). Do not edit.\n"
    + "nuon_install_id = \($nuon_install_id | @json)\n"
    + "nuon_org_id = \($nuon_org_id | @json)\n"
    + "nuon_app_id = \($nuon_app_id | @json)\n"
    + "nuon_support_iam_role_arns = \($nuon_support_iam_role_arns | @json)\n"
    + "aws_region = \($aws_region | @json)\n"
    + "runner_id = \($runner_id | @json)\n"
    + "runner_api_url = \($runner_api_url | @json)\n"
    + "phone_home_url = \($phone_home_url | @json)\n\n"
    + "install_inputs = {\n" + join("\n") + "\n}\n"
' <<<"$values" >"$out"

printf 'wrote %s\n' "$out"
