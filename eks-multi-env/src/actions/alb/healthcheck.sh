#!/usr/bin/env sh

set -e
set -o pipefail
set -u

echo >&2 "checking ingress..."

ingress_json=`kubectl get --namespace $INGRESS_NAMESPACE ingress $INGRESS_NAME -o json | jq -c`
status=`echo $ingress_json |jq -c '.status'`
certificate_arn=`echo $ingress_json |jq -r '.metadata.annotations."alb.ingress.kubernetes.io/certificate-arn"'`
hostname=`echo $ingress_json |jq -r '.metadata.annotations."external-dns.alpha.kubernetes.io/hostname"'`

# determine status
lb_ingress_count=`echo $status | jq '.loadBalancer.ingress | length'`
if [ "$lb_ingress_count" == "0" ];
  then
    indicator="🔴"
  else
    indicator="🟢"
fi

# compose the output
outputs=`jq --null-input --arg cert "$certificate_arn" --arg hn "$hostname" --arg indicatorVar "$indicator" --argjson statusVar "$status" '{"status": $statusVar, "indicator": $indicatorVar, "certificate_arn": $cert, "hostname": $hn}'`
echo $outputs >> $NUON_ACTIONS_OUTPUT_FILEPATH
