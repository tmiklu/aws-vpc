locals {
  map_subnets_to_tgw_attachment = { for k, v in aws_subnet.this : v["cidr_block"] => v }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count              = var.tgw-attachment["subnets"] == null ? 0 : 1
  subnet_ids         = values({ for k in var.tgw-attachment["subnets"] : k => local.map_subnets_to_tgw_attachment[k] })[*]["id"]
  transit_gateway_id = var.tgw-attachment["transit_gateway_id"]
  vpc_id             = aws_vpc.this.id
  #tags               = merge(module.label-attachment.tags, { "Name" : module.label-attachment.id })
}
