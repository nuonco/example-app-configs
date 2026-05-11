#!/usr/bin/env sh

set -e
set -o pipefail
set -u

AWS_PAGER=""
echo >&2 "checking alb upstreams"

# get ingress
ingress_json=$(kubectl get --namespace whoami ingress $INGRESS_NAME -o json | jq -c)

# get status
status=$(echo "$ingress_json" | jq -c '.status')

# ensure host exists (alb has been provisioned)
lb_ingress_count=$(echo "$status" | jq '.loadBalancer.ingress | length')
if [ "$lb_ingress_count" == "0" ]; then
  echo "no alb hostname found in ingress status"
  exit 1
fi

# get alb name from hostname
hostname=$(echo "$status" | jq -r '.loadBalancer.ingress[0].hostname')
lb_name=$(echo "$hostname" | sed 's/-[0-9]*\..*$//')

# get alb arn
alb_arn=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '${lb_name}')].LoadBalancerArn" \
  --output text)

if [ -z "$alb_arn" ]; then
  echo "no alb found matching ${lb_name}"
  exit 1
fi

# get target group arns for this alb
target_group_arns=$(aws elbv2 describe-target-groups \
  --load-balancer-arn "$alb_arn" \
  --query "TargetGroups[].TargetGroupArn" \
  --output text)

# collect health for each target group
results="[]"
for tg_arn in $target_group_arns; do
  tg_name=$(aws elbv2 describe-target-groups \
    --target-group-arns "$tg_arn" \
    --query "TargetGroups[0].TargetGroupName" \
    --output text)

  health=$(aws elbv2 describe-target-health \
    --target-group-arn "$tg_arn" | jq -c)

  entry=$(jq -n -c \
    --arg name "$tg_name" \
    --arg arn "$tg_arn" \
    --argjson health "$health" \
    '{target_group: $name, arn: $arn, health: $health}')

  results=$(echo "$results" | jq -c ". + [$entry]")
done

outputs=$(echo "$results" | jq -c  '.[0]')

echo "$outputs" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"
