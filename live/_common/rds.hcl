# How the rds component is wired. Shared by dev, staging and prod; values come from env.hcl.
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//rds"
}

# The database sits in the vpc's database subnets and only accepts traffic from the eks nodes.
dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../vpc"
  mock_outputs = {
    vpc_id                     = "vpc-00000000000000000"
    database_subnet_group_name = "mock-db-subnet-group"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "eks" {
  config_path = "${get_terragrunt_dir()}/../eks"
  mock_outputs = {
    node_security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  identifier                = "sqope-ai-${local.env.env}"
  vpc_id                    = dependency.vpc.outputs.vpc_id
  db_subnet_group_name      = dependency.vpc.outputs.database_subnet_group_name
  allowed_security_group_id = dependency.eks.outputs.node_security_group_id

  instance_class        = local.env.rds.instance_class
  allocated_storage     = local.env.rds.allocated_storage
  multi_az              = local.env.rds.multi_az
  backup_retention_days = local.env.rds.backup_retention_days
  deletion_protection   = local.env.rds.deletion_protection
}
