data "aws_region" "current" {}

locals {
  # Re-format additional subnets to the normalized form consumed by for_each iterations
  subnets = flatten([
    for name, values in var.subnets : [
      for subnet in values["subnets"] : merge({
        "name"                            = "${name}-${subnet}"
        "group"                           = "${name}"
        "subnet_suffix"                   = name
        "subnet"                          = subnet
        "ipv6_subnet"                     = try(element(values["ipv6_subnet"], index(values["subnets"], subnet)), null)
        "az"                              = element(try(values["azs"], var.azs), index(values["subnets"], subnet))
        "assign_ipv6_address_on_creation" = try(values["assign_ipv6_address_on_creation"], null)
        "customer_owned_ipv4_pool"        = try(values["customer_owned_ipv4_pool"], null)
        "ipv6_subnets"                    = try(values["ipv6_subnets"], null)
        "map_customer_owned_ip_on_launch" = try(values["map_customer_owned_ip_on_launch"], null)
        "outpost_arn"                     = try(values["outpost_arn"], null)
        "enable_nat_gateway"              = try(values["enable_nat_gateway"], false)
        "connectivity_type"               = try(values["connectivity_type"], null)
        "default_route_destination_type"  = try(values["default_route_destination_type"], null)
        "default_route_destination"       = try(values["default_route_destination"], null)
        "tags"                            = try(values["tags"], {})
      }, values)
    ]
  ])

  nat_gateway_subnets = { for subnet in local.subnets :
    subnet["connectivity_type"] == "private" ? "${subnet.group}-${subnet.az}-${subnet["connectivity_type"]}" :
  "${subnet.group}-${subnet.az}-${subnet["connectivity_type"]}" => subnet["name"] if subnet["enable_nat_gateway"] }

  default_route_destination_igw = [for subnet in local.subnets :
  subnet["name"] if subnet["default_route_destination_type"] == "igw"]

  default_route_destination_tgw = { for subnet in local.subnets :
  subnet["name"] => subnet["default_route_destination"] if subnet["default_route_destination_type"] == "tgw" }

  additional_route = { for subnet in local.subnets : subnet["name"] => subnet["additional_routes"] if can(subnet["additional_routes"]) }

  default_route_destination_natgw = { for subnet in local.subnets :
    subnet["name"] => try(
      aws_nat_gateway.this["${subnet.default_route_destination}-${subnet.az}-private"].id,
      aws_nat_gateway.this["${subnet.default_route_destination}-${subnet.az}-public"].id,
      try(
        aws_nat_gateway.this["${subnet.default_route_destination}-${data.aws_region.current.name}a-private"].id,
        aws_nat_gateway.this["${subnet.default_route_destination}-${data.aws_region.current.name}a-public"].id))
    if subnet["default_route_destination_type"] == "natgw"
  }
}
