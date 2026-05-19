#!/usr/bin/env bash
set -euo pipefail

if [ -z "${AWS_REGION:-}" ]; then
  echo "AWS_REGION is required for VPC dependency cleanup." >&2
  exit 1
fi

if [ -z "${VPC_ID:-}" ] || [ "${VPC_ID:-}" = "None" ]; then
  echo "VPC_ID is empty; skipping VPC dependency cleanup."
  exit 0
fi

aws_text_lines() {
  aws "$@" --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d;/^None$/d' || true
}

delete_elbv2_load_balancers() {
  mapfile -t load_balancer_arns < <(aws_text_lines elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn")

  if [ "${#load_balancer_arns[@]}" -eq 0 ]; then
    return 0
  fi

  for load_balancer_arn in "${load_balancer_arns[@]}"; do
    echo "Deleting ELBv2 load balancer: $load_balancer_arn"
    aws elbv2 delete-load-balancer \
      --region "$AWS_REGION" \
      --load-balancer-arn "$load_balancer_arn" || true
  done

  for load_balancer_arn in "${load_balancer_arns[@]}"; do
    aws elbv2 wait load-balancers-deleted \
      --region "$AWS_REGION" \
      --load-balancer-arns "$load_balancer_arn" || true
  done
}

delete_classic_load_balancers() {
  mapfile -t load_balancer_names < <(aws_text_lines elb describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancerDescriptions[?VPCId=='${VPC_ID}'].LoadBalancerName")

  for load_balancer_name in "${load_balancer_names[@]}"; do
    echo "Deleting classic load balancer: $load_balancer_name"
    aws elb delete-load-balancer \
      --region "$AWS_REGION" \
      --load-balancer-name "$load_balancer_name" || true
  done
}

delete_target_groups() {
  mapfile -t target_group_arns < <(aws_text_lines elbv2 describe-target-groups \
    --region "$AWS_REGION" \
    --query "TargetGroups[?VpcId=='${VPC_ID}'].TargetGroupArn")

  for target_group_arn in "${target_group_arns[@]}"; do
    echo "Deleting target group: $target_group_arn"
    aws elbv2 delete-target-group \
      --region "$AWS_REGION" \
      --target-group-arn "$target_group_arn" || true
  done
}

delete_vpc_endpoints() {
  mapfile -t endpoint_ids < <(aws_text_lines ec2 describe-vpc-endpoints \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "VpcEndpoints[].VpcEndpointId")

  if [ "${#endpoint_ids[@]}" -gt 0 ]; then
    echo "Deleting VPC endpoints: ${endpoint_ids[*]}"
    aws ec2 delete-vpc-endpoints \
      --region "$AWS_REGION" \
      --vpc-endpoint-ids "${endpoint_ids[@]}" || true
  fi
}

delete_nat_gateways() {
  mapfile -t nat_gateway_ids < <(aws_text_lines ec2 describe-nat-gateways \
    --region "$AWS_REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --query "NatGateways[?State!='deleted'].NatGatewayId")

  if [ "${#nat_gateway_ids[@]}" -eq 0 ]; then
    return 0
  fi

  for nat_gateway_id in "${nat_gateway_ids[@]}"; do
    echo "Deleting NAT gateway: $nat_gateway_id"
    aws ec2 delete-nat-gateway \
      --region "$AWS_REGION" \
      --nat-gateway-id "$nat_gateway_id" || true
  done

  aws ec2 wait nat-gateway-deleted \
    --region "$AWS_REGION" \
    --nat-gateway-ids "${nat_gateway_ids[@]}" || true
}

delete_network_interfaces() {
  local eni_json

  eni_json="$(aws ec2 describe-network-interfaces \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --output json 2>/dev/null || echo '{"NetworkInterfaces":[]}')"

  while IFS=$'\t' read -r eni_id attachment_id requester_managed status; do
    if [ -z "${eni_id:-}" ]; then
      continue
    fi

    if [ -n "${attachment_id:-}" ] && [ "$requester_managed" != "true" ]; then
      echo "Detaching network interface: $eni_id"
      aws ec2 detach-network-interface \
        --region "$AWS_REGION" \
        --attachment-id "$attachment_id" \
        --force || true
    elif [ -n "${attachment_id:-}" ]; then
      echo "Network interface $eni_id is requester-managed; waiting for owner cleanup."
    elif [ "$status" = "available" ]; then
      echo "Deleting available network interface: $eni_id"
      aws ec2 delete-network-interface \
        --region "$AWS_REGION" \
        --network-interface-id "$eni_id" || true
    fi
  done < <(printf '%s' "$eni_json" | jq -r '
    .NetworkInterfaces[]
    | [
        .NetworkInterfaceId,
        (.Attachment.AttachmentId // ""),
        (.RequesterManaged | tostring),
        (.Status // "")
      ]
    | @tsv
  ')

  for _ in $(seq 1 30); do
    mapfile -t eni_ids < <(aws_text_lines ec2 describe-network-interfaces \
      --region "$AWS_REGION" \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "NetworkInterfaces[].NetworkInterfaceId")

    if [ "${#eni_ids[@]}" -eq 0 ]; then
      echo "All network interfaces have been removed from $VPC_ID."
      return 0
    fi

    for eni_id in "${eni_ids[@]}"; do
      aws ec2 delete-network-interface \
        --region "$AWS_REGION" \
        --network-interface-id "$eni_id" || true
    done

    echo "Waiting for ${#eni_ids[@]} network interface(s) to disappear from $VPC_ID..."
    sleep 10
  done
}

delete_subnets() {
  mapfile -t subnet_ids < <(aws_text_lines ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[].SubnetId")

  for subnet_id in "${subnet_ids[@]}"; do
    echo "Deleting subnet: $subnet_id"
    aws ec2 delete-subnet \
      --region "$AWS_REGION" \
      --subnet-id "$subnet_id" || true
  done
}

delete_route_tables() {
  local route_table_json

  route_table_json="$(aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --output json 2>/dev/null || echo '{"RouteTables":[]}')"

  while read -r association_id; do
    if [ -n "${association_id:-}" ]; then
      echo "Disassociating route table association: $association_id"
      aws ec2 disassociate-route-table \
        --region "$AWS_REGION" \
        --association-id "$association_id" || true
    fi
  done < <(printf '%s' "$route_table_json" | jq -r '
    .RouteTables[].Associations[]?
    | select((.Main // false) == false)
    | .RouteTableAssociationId // empty
  ')

  while read -r route_table_id; do
    if [ -n "${route_table_id:-}" ]; then
      echo "Deleting route table: $route_table_id"
      aws ec2 delete-route-table \
        --region "$AWS_REGION" \
        --route-table-id "$route_table_id" || true
    fi
  done < <(printf '%s' "$route_table_json" | jq -r '
    .RouteTables[]
    | select(([.Associations[]? | select((.Main // false) == true)] | length) == 0)
    | .RouteTableId
  ')
}

delete_network_acls() {
  mapfile -t network_acl_ids < <(aws_text_lines ec2 describe-network-acls \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "NetworkAcls[?IsDefault==\`false\`].NetworkAclId")

  for network_acl_id in "${network_acl_ids[@]}"; do
    echo "Deleting network ACL: $network_acl_id"
    aws ec2 delete-network-acl \
      --region "$AWS_REGION" \
      --network-acl-id "$network_acl_id" || true
  done
}

delete_security_groups() {
  local sg_json

  sg_json="$(aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --output json 2>/dev/null || echo '{"SecurityGroups":[]}')"

  while read -r group_id; do
    if [ -z "${group_id:-}" ]; then
      continue
    fi

    ingress_permissions="$(printf '%s' "$sg_json" | jq -c --arg group_id "$group_id" '
      .SecurityGroups[]
      | select(.GroupId == $group_id)
      | .IpPermissions
    ')"
    egress_permissions="$(printf '%s' "$sg_json" | jq -c --arg group_id "$group_id" '
      .SecurityGroups[]
      | select(.GroupId == $group_id)
      | .IpPermissionsEgress
    ')"

    if [ -n "$ingress_permissions" ] && [ "$ingress_permissions" != "[]" ]; then
      echo "Revoking ingress rules from security group: $group_id"
      aws ec2 revoke-security-group-ingress \
        --region "$AWS_REGION" \
        --group-id "$group_id" \
        --ip-permissions "$ingress_permissions" || true
    fi

    if [ -n "$egress_permissions" ] && [ "$egress_permissions" != "[]" ]; then
      echo "Revoking egress rules from security group: $group_id"
      aws ec2 revoke-security-group-egress \
        --region "$AWS_REGION" \
        --group-id "$group_id" \
        --ip-permissions "$egress_permissions" || true
    fi
  done < <(printf '%s' "$sg_json" | jq -r '
    .SecurityGroups[]
    | select(.GroupName != "default")
    | .GroupId
  ')

  while read -r group_id; do
    if [ -n "${group_id:-}" ]; then
      echo "Deleting security group: $group_id"
      aws ec2 delete-security-group \
        --region "$AWS_REGION" \
        --group-id "$group_id" || true
    fi
  done < <(printf '%s' "$sg_json" | jq -r '
    .SecurityGroups[]
    | select(.GroupName != "default")
    | .GroupId
  ')
}

delete_internet_gateways() {
  mapfile -t igw_ids < <(aws_text_lines ec2 describe-internet-gateways \
    --region "$AWS_REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[].InternetGatewayId")

  for igw_id in "${igw_ids[@]}"; do
    echo "Detaching and deleting internet gateway: $igw_id"
    aws ec2 detach-internet-gateway \
      --region "$AWS_REGION" \
      --internet-gateway-id "$igw_id" \
      --vpc-id "$VPC_ID" || true
    aws ec2 delete-internet-gateway \
      --region "$AWS_REGION" \
      --internet-gateway-id "$igw_id" || true
  done
}

print_remaining_dependencies() {
  echo "Remaining dependencies in $VPC_ID after force cleanup:"

  aws ec2 describe-network-interfaces \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,Description:Description,RequesterManaged:RequesterManaged}" \
    --output table || true

  aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[].{Id:GroupId,Name:GroupName}" \
    --output table || true

  aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[].SubnetId" \
    --output table || true

  aws ec2 describe-vpc-endpoints \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "VpcEndpoints[].VpcEndpointId" \
    --output table || true
}

echo "Force-cleaning dependencies for VPC: $VPC_ID"

delete_elbv2_load_balancers
delete_classic_load_balancers
delete_target_groups
delete_vpc_endpoints
delete_nat_gateways
delete_network_interfaces
delete_subnets
delete_route_tables
delete_network_acls
delete_security_groups
delete_internet_gateways
print_remaining_dependencies
