# prod / eks. Wiring: live/_common/eks.hcl. Values: live/prod/env.hcl. State: prod/eks/terraform.tfstate
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/live/_common/eks.hcl"
}
