# How the vpc component is wired. Shared by dev, staging and prod; values come from env.hcl.
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//vpc"
}

inputs = {
  name               = "sqope-ai-${local.env.env}"
  cidr               = local.env.vpc.cidr
  azs                = [for az in ["a", "b", "c"] : "${local.env.region}${az}"]
  single_nat_gateway = local.env.vpc.single_nat_gateway
}
