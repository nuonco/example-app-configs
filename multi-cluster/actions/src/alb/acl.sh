#!/usr/bin/env sh

set -e
set -o pipefail
set -u

AWS_PAGER=""
echo >&2 "checking alb network acls"

ingress_json=$(kubectl get --namespace "$INGRESS_NAMESPACE" ingress "$INGRESS_NAME" -o json | jq -c)
status=$(echo "$ingress_json" | jq -c '.status')

lb_ingress_count=$(echo "$status" | jq '.loadBalancer.ingress | length')
if [ "$lb_ingress_count" == "0" ]; then
  echo "no alb hostname found in ingress status"
  exit 1
fi

hostname=$(echo "$status" | jq -r '.loadBalancer.ingress[0].hostname')
lb_name=$(echo "$hostname" | sed 's/-[0-9]*\..*$//')

alb=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '${lb_name}')] | [0]" \
  --output json | jq -c)

if [ "$alb" == "null" ]; then
  echo "no alb found matching ${lb_name}"
  exit 1
fi

subnet_ids=$(echo "$alb" | jq -r '.AvailabilityZones[].SubnetId')

results="[]"
for subnet_id in $subnet_ids; do
  nacl=$(aws ec2 describe-network-acls \
    --filters "Name=association.subnet-id,Values=${subnet_id}" \
    --query "NetworkAcls[0]" \
    --output json | jq -c)

  if [ "$nacl" == "null" ]; then
    continue
  fi

  nacl_id=$(echo "$nacl" | jq -r '.NetworkAclId')

  inbound=$(echo "$nacl" | jq -c '[.Entries[] | select(.Egress == false) | {
    rule_number: .RuleNumber,
    protocol: .Protocol,
    action: .RuleAction,
    cidr: .CidrBlock,
    from_port: .PortRange.From,
    to_port: .PortRange.To
  }] | sort_by(.rule_number)')

  outbound=$(echo "$nacl" | jq -c '[.Entries[] | select(.Egress == true) | {
    rule_number: .RuleNumber,
    protocol: .Protocol,
    action: .RuleAction,
    cidr: .CidrBlock,
    from_port: .PortRange.From,
    to_port: .PortRange.To
  }] | sort_by(.rule_number)')

  entry=$(jq -n -c \
    --arg subnet_id "$subnet_id" \
    --arg nacl_id "$nacl_id" \
    --argjson inbound "$inbound" \
    --argjson outbound "$outbound" \
    '{subnet_id: $subnet_id, nacl_id: $nacl_id, inbound: $inbound, outbound: $outbound}')

  results=$(echo "$results" | jq -c ". + [$entry]")
done

outputs=$(jq -n -c --argjson nacls "$results" '{network_acls: $nacls}')
echo "$outputs" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"
