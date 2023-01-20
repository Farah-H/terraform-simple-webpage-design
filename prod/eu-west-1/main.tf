module "webserver" {
  source = "../../modules/webserver/"

  region               = "eu-west-1"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidrs = ["10.0.101.0/24", "10.0.111.0/24", "10.0.121.0/24"]
  availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
