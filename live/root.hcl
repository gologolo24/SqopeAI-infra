# Included by every unit (live/<env>/<component>/terragrunt.hcl). Written once, used 9 times.
#
# 1. Remote state: every env x component gets its OWN state file in S3 (small blast radius).
# 2. Provider: generated per unit, locked to that environment's AWS account.

locals {
  env       = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  component = basename(get_terragrunt_dir())

  # Read-only by default (PR plans, laptops). Only the TeamCity apply builds set
  # TF_ROLE_NAME=terraform-deployer.
  role_name = get_env("TF_ROLE_NAME", "terraform-planner")
}

terraform_binary = "terraform"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # One versioned, encrypted bucket in the shared "tooling" account (where TeamCity runs).
    bucket = "sqope-ai-terraform-state"
    # path_relative_to_include() = "<env>/<component>", e.g. dev/vpc/terraform.tfstate
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true # S3-native locking, no DynamoDB table needed
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.env.region}"

      # Safety net: refuse to run against any account other than this environment's.
      allowed_account_ids = ["${local.env.account_id}"]

      # No static keys: the caller (TeamCity agent role / engineer SSO) assumes a role in the env account.
      assume_role {
        role_arn     = "arn:aws:iam::${local.env.account_id}:role/${local.role_name}"
        session_name = "terragrunt-${local.env.env}-${local.component}"
      }

      default_tags {
        tags = {
          Project     = "sqope-ai"
          Environment = "${local.env.env}"
          Component   = "${local.component}"
          ManagedBy   = "terragrunt"
          Repository  = "github.com/gologolo24/SqopeAI-infra"
        }
      }
    }
  EOF
}
