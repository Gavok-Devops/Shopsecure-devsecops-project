resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-redis-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags       = var.common_tags
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg-${var.environment}"
  description = "Redis access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project}-redis-sg" })
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-redis-${var.environment}"
  description          = "Redis cache for ${var.project} ${var.environment}"
  node_type            = var.node_type
  num_cache_clusters   = var.environment == "prod" ? 2 : 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auto_minor_version_upgrade = true
  tags = merge(var.common_tags, { Name = "${var.project}-redis" })
}
