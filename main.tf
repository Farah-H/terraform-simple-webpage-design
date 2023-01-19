locals {
  region = "eu-west-1"
  name   = "rapha"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${local.name}-simple-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a"]
  public_subnets = ["10.0.101.0/24"]
  create_igw     = true

  manage_default_network_acl   = true
  public_dedicated_network_acl = true
  default_network_acl_name     = "${local.name}-default-nacl"
  default_security_group_name  = "${local.name}-default-sg"
}

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "webserver" {
  name        = "webserver"
  description = "Allow All Traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow All Internet Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-public-sg"
  }
}

resource "aws_instance" "webserver" {
  ami                         = data.aws_ami.latest-ubuntu.id
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  monitoring                  = true
  security_groups             = [aws_security_group.webserver.id]
  user_data                   = file("./provision.sh")


  tags = {
    Name = "${local.name}-webserver-instance"
  }
}
