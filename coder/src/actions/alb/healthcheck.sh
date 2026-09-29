#!/usr/bin/env sh

set -e
set -o pipefail
set -u

echo "checking coder ingress..."

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

outputs=$(jq --null-input -c \
  --arg coder_cert "$coder_cert" \
  --arg coder_hn "$coder_hostname" \
  --arg coder_ind "$coder_indicator" \
  --argjson coder_status "$coder_status" \
  --arg updated_at "$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    "updated_at": $updated_at,
    "coder": {"status": $coder_status, "indicator": $coder_ind, "certificate_arn": $coder_cert, "hostname": $coder_hn}
  }')
echo $outputs >> $NUON_ACTIONS_OUTPUT_FILEPATH
