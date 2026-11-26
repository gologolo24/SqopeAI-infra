# Network for one environment: 3 AZs, each with a public, a private and a database subnet.
#
#   public   /24  load balancers + NAT gateways      (internet-facing)
#   private  /20  EKS worker nodes and pods          (no inbound from the internet)
#   database /24  RDS only                           (no route to the internet at all)

locals {
  private_subnets  = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i)]      # 10.x.0.0/20, 10.x.16.0/20, 10.x.32.0/20
  public_subnets   = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, 48 + i)] # 10.x.48.0/24 ...
  database_subnets = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, 64 + i)] # 10.x.64.0/24 ...
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.9.0"

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  create_database_subnet_group = true

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true

  # Lets the AWS Load Balancer Controller find the right subnets for public / internal LBs.
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }

  # Network audit trail: who talked to whom (security investigations, debugging).
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = 30
}
