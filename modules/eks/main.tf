# Kubernetes cluster for one environment. The Sqope AI services (and ArgoCD) run here.
#
# Nodes live in the PRIVATE subnets. The control plane is reachable privately from inside the VPC
# and publicly ONLY from allow-listed CIDRs (office VPN / CI agents).

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.30.2"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.api_allowed_cidrs

  # Whoever creates the cluster (the CI deployer role) gets admin via EKS access entries.
  # Humans get access through access entries / SSO roles, not through the aws-auth ConfigMap.
  enable_cluster_creator_admin_permissions = true

  # Control-plane audit logs to CloudWatch (who did what in the cluster).
  enabled_log_types = ["api", "audit", "authenticator"]

  addons = {
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true } # pods get AWS permissions without static keys
    coredns                = {}
    kube-proxy             = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }
}
