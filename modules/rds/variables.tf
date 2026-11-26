variable "identifier" {
  description = "DB instance name, e.g. sqope-ai-dev"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_group_name" {
  description = "From the vpc component (database subnets)"
  type        = string
}

variable "allowed_security_group_id" {
  description = "The only security group allowed to connect (EKS nodes, from the eks component)"
  type        = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  description = "Initial storage in GiB (autoscales up to 5x)"
  type        = number
}

variable "multi_az" {
  description = "Standby replica in a second AZ with automatic failover"
  type        = bool
}

variable "backup_retention_days" {
  type = number
}

variable "deletion_protection" {
  description = "Blocks deletion (and keeps a final snapshot) - on for staging/prod"
  type        = bool
}
