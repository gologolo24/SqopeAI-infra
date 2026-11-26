# prod / rds. Wiring: live/_common/rds.hcl. Values: live/prod/env.hcl. State: prod/rds/terraform.tfstate
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/live/_common/rds.hcl"
}
