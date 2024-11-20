variable "namespace" {
  type        = string
  default     = null
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT'"
}

variable "stage" {
  type        = string
  default     = null
  description = "Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release'"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "context" {
  description = "Single object for setting entire context at once."
  type        = any
  default = {
    enabled             = true
    namespace           = null
    environment         = null
    stage               = null
    name                = null
    delimiter           = null
    attributes          = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = null
    label_order         = []
    id_length_limit     = null
    label_key_case      = null
    label_value_case    = null
  }
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "secondary_cidr" {
  description = "VPC secondary cidr block"
  default     = null
  type        = string
}

variable "vpc_enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true."
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = false
}

variable "igw_tags" {
  description = "Additional tags for the internet gateway"
  type        = map(string)
  default     = {}
}

variable "azs" {
  description = "Map of strings that indentify availability zones in VPC"
  type        = list(string)
  default     = []
}

#Do not delete!
# variable "subnets" {
# description = "Additional subnet map where key is subnet group name"
# Keys except `subnets` are optional
# type = map(object({
# azs                             = list(string)
# subnets                         = list(string)
# ipv6_subnets                    = list(string)
# customer_owned_ipv4_pool        = string
# map_customer_owned_ip_on_launch = bool
# outpost_arn                     = string
# assign_ipv6_address_on_creation = bool
# dedicated_network_acl           = bool
# default_network_acl_rules       = bool
# enable_nat_gateway              = bool
# enable_private_nat_gateway      = bool
# default_route_destination_type  = string
# default_route_destination       = string
# inbound_acl_rules               = list(map(string))
# outbound_acl_rules              = list(map(string))
# tags                            = map(string)
# }))
# default = {}
# }
variable "subnets" {
  description = "See comment above"
  type        = any
}

variable "tgw-attachment" {
  description = "TGW attachment for transit gateway"
  type        = any
  default     = {}
}
