#!/usr/bin/env sh

set -e
set -o pipefail
set -u

echo "checking gateway..."

gw_json=$(kubectl get -n "$GATEWAY_NAMESPACE" gateway "$GATEWAY_NAME" -o json | jq -c)
gw_addresses=$(echo "$gw_json" | jq -c '.status.addresses // []')
gw_addr_count=$(echo "$gw_addresses" | jq 'length')

if [ "$gw_addr_count" = "0" ]; then
  gw_indicator="🔴"
else
  gw_indicator="🟢"
fi

# coder route
coder_json=$(kubectl get -n "$GATEWAY_NAMESPACE" httproute "$CODER_ROUTE_NAME" -o json | jq -c)
coder_parents=$(echo "$coder_json" | jq -c '.status.parents // []')
coder_accepted=$(echo "$coder_parents" | jq '[.[].conditions[] | select(.type=="Accepted" and .status=="True")] | length')
if [ "$coder_accepted" = "0" ]; then
  coder_indicator="🔴"
else
  coder_indicator="🟢"
fi

# grafana route
grafana_json=$(kubectl get -n "$GATEWAY_NAMESPACE" httproute "$GRAFANA_ROUTE_NAME" -o json 2>/dev/null | jq -c)
if [ -z "$grafana_json" ] || [ "$grafana_json" = "null" ]; then
  grafana_indicator="🔴"
  grafana_parents="[]"
else
  grafana_parents=$(echo "$grafana_json" | jq -c '.status.parents // []')
  grafana_accepted=$(echo "$grafana_parents" | jq '[.[].conditions[] | select(.type=="Accepted" and .status=="True")] | length')
  if [ "$grafana_accepted" = "0" ]; then
    grafana_indicator="🔴"
  else
    grafana_indicator="🟢"
  fi
fi

outputs=$(jq --null-input --compact-output \
  --argjson gw_addresses "$gw_addresses" \
  --arg gw_ind "$gw_indicator" \
  --argjson coder_parents "$coder_parents" \
  --arg coder_ind "$coder_indicator" \
  --argjson grafana_parents "$grafana_parents" \
  --arg grafana_ind "$grafana_indicator" \
  '{
    "gateway":  {"indicator": $gw_ind, "addresses": $gw_addresses},
    "coder":    {"indicator": $coder_ind, "parents": $coder_parents},
    "grafana":  {"indicator": $grafana_ind, "parents": $grafana_parents}
  }')
printf '%s' "$outputs" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"
