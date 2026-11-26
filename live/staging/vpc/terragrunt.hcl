# staging / vpc. Wiring: live/_common/vpc.hcl. Values: live/staging/env.hcl. State: staging/vpc/terraform.tfstate
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/live/_common/vpc.hcl"
}
