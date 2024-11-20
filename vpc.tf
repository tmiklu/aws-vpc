resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  enable_dns_support   = var.vpc_enable_dns_support
  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}" },
    var.tags
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count      = var.secondary_cidr != null ? 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr
}

resource "aws_internet_gateway" "this" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}" },
    var.tags,
    var.igw_tags
  )
}

resource "aws_eip" "this" {
  for_each = { for k, v in local.nat_gateway_subnets : k => v if !endswith(k, "private") }
  depends_on = [
    aws_internet_gateway.this
  ]

  domain = "vpc"
  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}" },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_subnets

  allocation_id     = contains(split("-", each.key), "private") ? null : aws_eip.this[each.key].id
  connectivity_type = contains(split("-", each.key), "private") ? "private" : "public"
  subnet_id         = aws_subnet.this[each.value].id
  tags              = merge(module.label.tags, { "Name" : "${var.name}-${aws_subnet.this[each.value].availability_zone}" })
}
