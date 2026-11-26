# prod: highly available and protected. NAT per AZ, on-demand nodes across 3 AZs,
# multi-AZ database with 30 days of backups and deletion protection.
locals {
  env        = "prod"
  account_id = "333333333333" # placeholder - one AWS account per environment
  region     = "eu-central-1"

  vpc = {
    cidr               = "10.30.0.0/16"
    single_nat_gateway = false
  }

  eks = {
    version           = "1.34"
    instance_types    = ["m6i.xlarge"]
    capacity_type     = "ON_DEMAND"
    min_size          = 3
    max_size          = 10
    desired_size      = 3
    api_allowed_cidrs = ["203.0.113.0/24"] # placeholder - office VPN + CI agents' NAT IPs
  }

  rds = {
    instance_class        = "db.r7g.large"
    allocated_storage     = 100
    multi_az              = true
    backup_retention_days = 30
    deletion_protection   = true
  }
}
