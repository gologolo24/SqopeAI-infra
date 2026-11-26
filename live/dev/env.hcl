# dev: everything that makes dev different from staging/prod lives in this one file.
# Optimised for cost: single NAT, spot nodes, small single-AZ database, no deletion protection.
locals {
  env        = "dev"
  account_id = "111111111111" # placeholder - one AWS account per environment
  region     = "eu-central-1"

  vpc = {
    cidr               = "10.10.0.0/16"
    single_nat_gateway = true
  }

  eks = {
    version           = "1.34"
    instance_types    = ["t3.large"]
    capacity_type     = "SPOT"
    min_size          = 2
    max_size          = 4
    desired_size      = 2
    api_allowed_cidrs = ["203.0.113.0/24"] # placeholder - office VPN + CI agents' NAT IPs
  }

  rds = {
    instance_class        = "db.t4g.micro"
    allocated_storage     = 20
    multi_az              = false
    backup_retention_days = 1
    deletion_protection   = false
  }
}
