# PostgreSQL for one environment, in the isolated database subnets.
#
# - Reachable ONLY from the EKS worker nodes (security group reference, not a CIDR).
# - The master password is generated and stored by AWS in Secrets Manager
#   (manage_master_user_password): it never appears in code, in Terraform state outputs or in CI.

resource "aws_security_group" "db" {
  name_prefix = "${var.identifier}-db-"
  description = "PostgreSQL - only reachable from EKS nodes"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_eks_nodes" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.allowed_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from EKS nodes"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.2"

  identifier = var.identifier

  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 5 # storage autoscaling
  storage_encrypted     = true

  db_name                     = "sqope"
  username                    = "sqope_admin"
  port                        = 5432
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  create_db_subnet_group = false
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = !var.deletion_protection # protected environments keep a final snapshot

  create_db_option_group = false # PostgreSQL doesn't use option groups
}
