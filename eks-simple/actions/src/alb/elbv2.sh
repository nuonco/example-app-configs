#!/usr/bin/env sh

set -e
set -o pipefail
set -u

AWS_PAGER=""
echo >&2 "checking alb"

# get ingress
ingress_json=`kubectl get --namespace whoami ingress $INGRESS_NAME -o json | jq -c`

# get status
status=`echo $ingress_json |jq -c '.status'`

# ensure host exists (alb has been provisioned)
lb_ingress_count=`echo $status | jq '.loadBalancer.ingress | length'`
if [ "$lb_ingress_count" == "0" ];
  then
    echo "no alb hostname found in ingress status"
    exit 1
fi

# get alb name from hostname
hostname=$(echo "$status" | jq -r '.loadBalancer.ingress[0].hostname')
lb_name=$(echo "$hostname" | sed 's/-[0-9]*\..*$//')

# get alb details
outputs=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '${lb_name}')]" | jq -c '.[0]')


echo $outputs >> $NUON_ACTIONS_OUTPUT_FILEPATH
