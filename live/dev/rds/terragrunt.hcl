# dev / rds. Wiring: live/_common/rds.hcl. Values: live/dev/env.hcl. State: dev/rds/terraform.tfstate
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/live/_common/rds.hcl"
}
