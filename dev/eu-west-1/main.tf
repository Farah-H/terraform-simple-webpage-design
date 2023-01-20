module "webserver" {
  source = "../../modules/webserver/"

  region               = "eu-west-1"
  vpc_cidr             = "10.4.0.0/16"
  public_subnets_cidrs = ["10.4.101.0/24"]
  availability_zones   = ["eu-west-1a"]

  env = "dev"

  min_size = 1
  max_size = 1
}
