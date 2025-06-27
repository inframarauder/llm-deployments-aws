# fetch availability zones - 
data "aws_availability_zones" "azs" {
  state = "available"
}
# create a VPC with public, private subnets for AI workloads
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.20.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.azs.names
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # tags necessary for ALB Ingress Controller
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  depends_on = [data.aws_availability_zones.azs]
}
