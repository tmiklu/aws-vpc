resource "aws_route_table" "this" {
  for_each = {
    for subnet in local.subnets : "${subnet.name}" => subnet
  }

  vpc_id = aws_vpc.this.id

  tags = merge(
    module.label.tags,
    { "Name" : "${var.name}-${each.value.group}-${each.value.az}" },
    var.tags,
    try(each.value.route_table_tags, {}),
  )
}

resource "aws_route" "this_igw" {
  for_each = toset(local.default_route_destination_igw)

  route_table_id         = aws_route_table.this[each.key].id
  gateway_id             = aws_internet_gateway.this[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "this_tgw" {
  for_each = local.default_route_destination_tgw

  route_table_id         = aws_route_table.this[each.key].id
  transit_gateway_id     = each.value
  destination_cidr_block = "0.0.0.0/0"

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_route" "this_natgw" {
  for_each = local.default_route_destination_natgw

  route_table_id         = aws_route_table.this[each.key].id
  nat_gateway_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "this_peering" {
  for_each = local.additional_route

  route_table_id            = aws_route_table.this[each.key].id
  vpc_peering_connection_id = each.value["peering"]["id"]
  destination_cidr_block    = each.value["peering"]["destination"]
}

resource "aws_route_table_association" "this" {
  for_each = {
    for subnet in local.subnets : "${subnet.name}" => subnet
  }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}
