terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "shopsecure-terraform-state-887998956998"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopsecure-terraform-locks"
    encrypt        = true
  }
}

provider "aws" { region = "us-east-1" }

# ── Reference existing Route53 hosted zone ────────────────────────────────────
data "aws_route53_zone" "main" {
  name         = "teamcsolutions.com."
  private_zone = false
}

# ── ACM wildcard certificate (us-east-1 required for CloudFront) ──────────────
resource "aws_acm_certificate" "main" {
  domain_name               = "teamcsolutions.com"
  subject_alternative_names = ["*.teamcsolutions.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = "shopsecure"
    Environment = "prod"
    ManagedBy   = "terraform"
    Domain      = "teamcsolutions.com"
  }
}

# ── DNS validation CNAME records in existing zone ─────────────────────────────
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ── Wait for certificate to be issued ────────────────────────────────────────
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "zone_id" {
  description = "Route53 hosted zone ID for teamcsolutions.com"
  value       = data.aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone name"
  value       = data.aws_route53_zone.main.name
}

output "certificate_arn" {
  description = "ACM certificate ARN — use this in ALB and CloudFront"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain" {
  description = "Primary domain on the certificate"
  value       = aws_acm_certificate.main.domain_name
}
