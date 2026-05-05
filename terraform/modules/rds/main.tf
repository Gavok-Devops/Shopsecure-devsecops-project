resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.project}-rds-subnet-group" })
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg-${var.environment}"
  description = "PostgreSQL access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project}-rds-sg" })
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project}/${var.environment}/database"
  recovery_window_in_days = 7
  tags                    = var.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username       = var.db_username
    password       = random_password.db_password.result
    dbname         = var.db_name
    host           = aws_db_instance.main.address
    port           = 5432
    connection_url = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.address}:5432/${var.db_name}"
  })
}

resource "aws_db_instance" "main" {
  identifier                   = "${var.project}-postgres-${var.environment}"
  engine                       = "postgres"
  engine_version               = "17.9"
  instance_class               = var.instance_class
  allocated_storage            = 100
  max_allocated_storage        = 500
  storage_encrypted            = true
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = random_password.db_password.result
  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = [aws_security_group.rds.id]
  multi_az                     = var.multi_az
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.project}-final-snapshot-${var.environment}"
  deletion_protection          = var.deletion_protection
  backup_retention_period      = 7
  backup_window                = "03:00-04:00"
  maintenance_window           = "Mon:04:00-Mon:05:00"
  performance_insights_enabled = true
  tags                         = merge(var.common_tags, { Name = "${var.project}-postgres" })
}
