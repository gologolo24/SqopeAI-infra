output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_security_group_id" {
  description = "Security group of the worker nodes (the database allows traffic only from it)"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "For IRSA roles (e.g. External Secrets, AWS Load Balancer Controller)"
  value       = module.eks.oidc_provider_arn
}
