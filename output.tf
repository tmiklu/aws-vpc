output "vpc" {
  value = aws_vpc.this
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "subnet_groups" {
  description = "List of subnet group names"
  value = [
    for k, v in var.subnets : k
  ]
}

output "subnets" {
  description = "Map of subnets where key is subnet group name and values are attributes"
  value = {
    for group, v in var.subnets :
    group => {
      for subnet in local.subnets :
      aws_subnet.this[subnet.name].id => aws_subnet.this[subnet.name]
      if subnet.group == group
    }
  }
}

output "private_subnets" {
  description = "Temp output, until we use only this module and not legacy ones."
  value = [
    for subnet in local.subnets :
    aws_subnet.this[subnet.name].id if subnet.group == "private-subnets"
  ]

}

output "route_tables" {
  description = "Map of additional route tables IDs where key is subnet group name and attributes is another nasted map with route table id and route table attributes with az information "
  value = {
    for group, v in var.subnets :
    (group) => {
      for subnet in local.subnets :
      aws_route_table.this[subnet.name].id => merge(
        aws_route_table.this[subnet.name],
        {
          az = subnet.az
        }
      )
      if subnet.group == group
    }
  }
}
