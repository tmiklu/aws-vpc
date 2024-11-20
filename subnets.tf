locals {
  # Normalize inbound custom acl rules
  # convert from list of rules to map with additional subnet name as key
  acl_rules_inbound = merge([
    for name, attributes in var.subnets : {
      for rule in attributes.inbound_acl_rules :
      "${name}-${rule.rule_number}" => merge(
        { subnet_name = name },
        rule
    ) }
    if can(attributes.inbound_acl_rules)
  ]...)

  # Normalize outbound custom acl rules
  # convert from list of rules to map with additional subnet name as key
  acl_rules_outbound = merge([
    for name, attributes in var.subnets : {
      for rule in attributes.outbound_acl_rules :
      "${name}-${rule.rule_number}" => merge(
        { subnet_name = name },
        rule
    ) }
    if can(attributes.outbound_acl_rules)
  ]...)
}

resource "aws_subnet" "this" {
  for_each = {
    for subnet in local.subnets : "${subnet.name}" => subnet
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.subnet
  availability_zone = each.value.az

  customer_owned_ipv4_pool        = try(each.value.customer_owned_ipv4_pool, null)
  map_customer_owned_ip_on_launch = try(each.value.map_customer_owned_ip_on_launch, null)
  outpost_arn                     = try(each.value.outpost_arn, null)
  assign_ipv6_address_on_creation = try(each.value.assign_ipv6_address_on_creation, null)
  ipv6_cidr_block                 = try(each.value.ipv6_subnet, null)

  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}-${each.value.group}-${each.value.az}" },
    try(each.value.tags, {})
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to the tags["karpenter.sh/discovery"] attribute
      tags["karpenter.sh/discovery"],
      tags["kubernetes.io/role/internal-elb"]
    ]
  }

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

resource "aws_network_acl" "this" {
  for_each = {
    for k, v in var.subnets : k => v
    if try(v.dedicated_network_acl, true)
  }

  vpc_id = aws_vpc.this.id
  subnet_ids = [
    for subnet in local.subnets : aws_subnet.this[subnet.name].id
    if subnet.group == each.key
  ]

  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}-${each.key}" },
    var.tags,
    try(each.value.acl_tags, {}),
  )
}

resource "aws_network_acl_rule" "inbound_default" {
  for_each = {
    for k, v in var.subnets : k => v
    if !can(v.inbound_acl_rules)
  }

  network_acl_id = aws_network_acl.this[each.key].id

  egress      = false
  rule_number = 100
  rule_action = "allow"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_block  = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "outbound_default" {
  for_each = {
    for k, v in var.subnets : k => v
    if !can(v.outbound_acl_rules)
  }

  network_acl_id = aws_network_acl.this[each.key].id

  egress      = true
  rule_number = 100
  rule_action = "allow"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_block  = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "inbound_custom" {
  for_each = local.acl_rules_inbound

  network_acl_id = aws_network_acl.this[each.value.subnet_name].id

  egress      = false
  rule_number = each.value.rule_number
  rule_action = each.value.rule_action
  protocol    = each.value.protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)
  icmp_code   = try(each.value.icmp_code, null)
  icmp_type   = try(each.value.icmp_type, null)
  cidr_block  = try(each.value.cidr_block, null)
}

resource "aws_network_acl_rule" "outbound_custom" {
  for_each = local.acl_rules_outbound

  network_acl_id = aws_network_acl.this[each.value.subnet_name].id

  egress      = true
  rule_number = each.value.rule_number
  rule_action = each.value.rule_action
  protocol    = each.value.protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)
  icmp_code   = try(each.value.icmp_code, null)
  icmp_type   = try(each.value.icmp_type, null)
  cidr_block  = try(each.value.cidr_block, null)
}
