variable "name" {
  description = "Cluster name, e.g. sqope-ai-dev"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version, e.g. 1.34"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the nodes (from the vpc component)"
  type        = list(string)
}

variable "api_allowed_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API (VPN, CI agents). Never 0.0.0.0/0."
  type        = list(string)
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_capacity_type" {
  description = "ON_DEMAND, or SPOT to cut cost in non-production"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}
