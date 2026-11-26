# staging: same TOPOLOGY as prod (NAT per AZ, multi-AZ DB, deletion protection) at a smaller size,
# so problems that only show up in a prod-like setup are caught before prod.
locals {
  env        = "staging"
  account_id = "222222222222" # placeholder - one AWS account per environment
  region     = "eu-central-1"

  vpc = {
    cidr               = "10.20.0.0/16"
    single_nat_gateway = false
  }

  eks = {
    version           = "1.34"
    instance_types    = ["m6i.large"]
    capacity_type     = "ON_DEMAND"
    min_size          = 2
    max_size          = 4
    desired_size      = 2
    api_allowed_cidrs = ["203.0.113.0/24"] # placeholder - office VPN + CI agents' NAT IPs
  }

  rds = {
    instance_class        = "db.t4g.medium"
    allocated_storage     = 50
    multi_az              = true
    backup_retention_days = 7
    deletion_protection   = true
  }
}
