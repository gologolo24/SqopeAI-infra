variable "name" {
  description = "Name prefix, e.g. sqope-ai-dev"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block (a /16), unique per environment so VPCs can be peered later"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across (3 for high availability)"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (cheap, dev). false = one NAT per AZ (survives an AZ outage)"
  type        = bool
  default     = false
}
