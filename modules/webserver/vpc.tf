locals {
  region    = var.region
  name      = "rapha"
  prod_only = var.env == "prod" ? 1 : 0
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${local.name}-simple-vpc"
  cidr = "10.0.0.0/16"

  azs            = var.availability_zones
  public_subnets = var.public_subnets_cidrs
  create_igw     = true

  manage_default_network_acl   = true
  public_dedicated_network_acl = true
  default_network_acl_name     = "${local.name}-default-nacl"
  default_security_group_name  = "${local.name}-default-sg"
}
