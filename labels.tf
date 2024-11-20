module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  name        = "terraform-aws-vpc-module"
  attributes  = var.attributes
  tags = merge(
    var.tags,
    { "terraform-module" = "terraform-aws-vpc" }
  )
  context = var.context
}
