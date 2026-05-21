#!/usr/bin/env sh

set -e
set -o pipefail
set -u

AWS_PAGER=""
echo >&2 "checking alb security groups"

ingress_json=$(kubectl get --namespace "$INGRESS_NAMESPACE" ingress "$INGRESS_NAME" -o json | jq -c)
status=$(echo "$ingress_json" | jq -c '.status')

lb_ingress_count=$(echo "$status" | jq '.loadBalancer.ingress | length')
if [ "$lb_ingress_count" == "0" ]; then
  echo "no alb hostname found in ingress status"
  exit 1
fi

hostname=$(echo "$status" | jq -r '.loadBalancer.ingress[0].hostname')
lb_name=$(echo "$hostname" | sed 's/-[0-9]*\..*$//')

alb_arn=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '${lb_name}')].LoadBalancerArn" \
  --output text)

if [ -z "$alb_arn" ]; then
  echo "no alb found matching ${lb_name}"
  exit 1
fi

sg_ids=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$alb_arn" \
  --query "LoadBalancers[0].SecurityGroups[]" \
  --output text)

results="[]"
for sg_id in $sg_ids; do
  sg_details=$(aws ec2 describe-security-groups \
    --group-ids "$sg_id" \
    --query "SecurityGroups[0]" | jq -c)

  ingress_rules=$(echo "$sg_details" | jq -c '[.IpPermissions[] | {
    protocol: .IpProtocol,
    from_port: .FromPort,
    to_port: .ToPort,
    cidrs: [.IpRanges[].CidrIp],
    source_sgs: [.UserIdGroupPairs[].GroupId]
  }]')

  entry=$(jq -n -c \
    --arg sg_id "$sg_id" \
    --arg sg_name "$(echo "$sg_details" | jq -r '.GroupName')" \
    --argjson ingress "$ingress_rules" \
    '{security_group_id: $sg_id, name: $sg_name, ingress_rules: $ingress}')

  results=$(echo "$results" | jq -c ". + [$entry]")
done

outputs=$(jq -n -c --argjson sgs "$results" '{security_groups: $sgs}')
echo "$outputs" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"
