#!/usr/bin/env sh

set -e
set -o pipefail
set -u

echo "checking sonarqube ingress..."

sonar_json=$(kubectl get --namespace $INGRESS_NAMESPACE ingress $INGRESS_NAME -o json | jq -c)
sonar_status=$(echo $sonar_json | jq -c '.status')
sonar_cert=$(echo $sonar_json | jq -r '.metadata.annotations."alb.ingress.kubernetes.io/certificate-arn"')
sonar_hostname=$(echo $sonar_json | jq -r '.metadata.annotations."external-dns.alpha.kubernetes.io/hostname"')

sonar_lb_count=$(echo $sonar_status | jq '.loadBalancer.ingress | length')
if [ "$sonar_lb_count" = "0" ]; then
  sonar_indicator="🔴"
else
  sonar_indicator="🟢"
fi

outputs=$(jq --null-input -c \
  --arg sonar_cert "$sonar_cert" \
  --arg sonar_hn "$sonar_hostname" \
  --arg sonar_ind "$sonar_indicator" \
  --argjson sonar_status "$sonar_status" \
  --arg updated_at "$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    "updated_at": $updated_at,
    "sonarqube": {"status": $sonar_status, "indicator": $sonar_ind, "certificate_arn": $sonar_cert, "hostname": $sonar_hn}
  }')
echo $outputs >> $NUON_ACTIONS_OUTPUT_FILEPATH
