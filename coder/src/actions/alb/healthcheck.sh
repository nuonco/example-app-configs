#!/usr/bin/env sh

set -e
set -o pipefail
set -u

# check coder ingress
echo >&2 "checking coder ingress..."

coder_json=$(kubectl get --namespace $INGRESS_NAMESPACE ingress $INGRESS_NAME -o json | jq -c)
coder_status=$(echo $coder_json | jq -c '.status')
coder_cert=$(echo $coder_json | jq -r '.metadata.annotations."alb.ingress.kubernetes.io/certificate-arn"')
coder_hostname=$(echo $coder_json | jq -r '.metadata.annotations."external-dns.alpha.kubernetes.io/hostname"')

coder_lb_count=$(echo $coder_status | jq '.loadBalancer.ingress | length')
if [ "$coder_lb_count" = "0" ]; then
  coder_indicator="🔴"
else
  coder_indicator="🟢"
fi

# check grafana ingress
echo >&2 "checking grafana ingress..."

grafana_json=$(kubectl get --namespace $GRAFANA_INGRESS_NAMESPACE ingress -o json | jq -c '.items[0]')
if [ "$grafana_json" = "null" ]; then
  grafana_indicator="🔴"
  grafana_status="null"
  grafana_hostname="null"
else
  grafana_status=$(echo $grafana_json | jq -c '.status')
  grafana_hostname=$(echo $grafana_json | jq -r '.metadata.annotations."external-dns.alpha.kubernetes.io/hostname" // empty')

  grafana_lb_count=$(echo $grafana_status | jq '.loadBalancer.ingress | length')
  if [ "$grafana_lb_count" = "0" ]; then
    grafana_indicator="🔴"
  else
    grafana_indicator="🟢"
  fi
fi

# compose the output
outputs=$(jq --null-input \
  --arg coder_cert "$coder_cert" \
  --arg coder_hn "$coder_hostname" \
  --arg coder_ind "$coder_indicator" \
  --argjson coder_status "$coder_status" \
  --arg grafana_hn "$grafana_hostname" \
  --arg grafana_ind "$grafana_indicator" \
  --argjson grafana_status "$grafana_status" \
  '{
    "coder": {"status": $coder_status, "indicator": $coder_ind, "certificate_arn": $coder_cert, "hostname": $coder_hn},
    "grafana": {"status": $grafana_status, "indicator": $grafana_ind, "hostname": $grafana_hn}
  }')
echo $outputs >> $NUON_ACTIONS_OUTPUT_FILEPATH
