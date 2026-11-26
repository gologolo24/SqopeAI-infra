# How the eks component is wired. Shared by dev, staging and prod; values come from env.hcl.
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//eks"
}

# eks needs the network first. Terragrunt reads the vpc component's outputs from ITS state,
# and `run --all` applies vpc before eks automatically.
dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../vpc"

  # Placeholders used only before the vpc exists (first plan, validate), so the whole
  # environment can be planned in one go.
  mock_outputs = {
    vpc_id          = "vpc-00000000000000000"
    private_subnets = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name               = "sqope-ai-${local.env.env}"
  kubernetes_version = local.env.eks.version
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_ids         = dependency.vpc.outputs.private_subnets
  api_allowed_cidrs  = local.env.eks.api_allowed_cidrs

  node_instance_types = local.env.eks.instance_types
  node_capacity_type  = local.env.eks.capacity_type
  node_min_size       = local.env.eks.min_size
  node_max_size       = local.env.eks.max_size
  node_desired_size   = local.env.eks.desired_size
}
