terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    random     = { source = "hashicorp/random", version = "~> 3.0" }
    tls        = { source = "hashicorp/tls", version = "~> 4.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.27" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13" }
  }

  backend "s3" {
    bucket         = "shopsecure-terraform-state-887998956998"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopsecure-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

locals {
  domain_name = "teamcsolutions.com"
  common_tags = {
    Project     = "shopsecure"
    Environment = "prod"
    ManagedBy   = "terraform"
    Domain      = local.domain_name
    Team        = "platform"
  }
}

# ── Reference global outputs (cert + zone) ────────────────────────────────────
data "aws_route53_zone" "main" {
  name         = "${local.domain_name}."
  private_zone = false
}

data "aws_acm_certificate" "main" {
  domain      = local.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source             = "../../modules/vpc"
  project            = "shopsecure"
  environment        = "prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  common_tags        = local.common_tags
}

# ── ECR ───────────────────────────────────────────────────────────────────────
module "ecr" {
  source      = "../../modules/ecr"
  project     = "shopsecure"
  environment = "prod"
  common_tags = local.common_tags
}

# ── EKS ───────────────────────────────────────────────────────────────────────
module "eks" {
  source              = "../../modules/eks"
  project             = "shopsecure"
  environment         = "prod"
  kubernetes_version  = "1.31"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  cluster_admin_cidrs = var.cluster_admin_cidrs
  common_tags         = local.common_tags
}

# ── RDS PostgreSQL ────────────────────────────────────────────────────────────
module "rds" {
  source                     = "../../modules/rds"
  project                    = "shopsecure"
  environment                = "prod"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.m5.large"
  multi_az                   = true
  skip_final_snapshot        = false
  deletion_protection        = true
  common_tags                = local.common_tags
}

# ── ElastiCache Redis ─────────────────────────────────────────────────────────
module "elasticache" {
  source                     = "../../modules/elasticache"
  project                    = "shopsecure"
  environment                = "prod"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  node_type                  = "cache.m5.large"
  common_tags                = local.common_tags
}

# ── AWS Load Balancer Controller ──────────────────────────────────────────────
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [module.eks]
}

# ── Route53 DNS records for platform services ─────────────────────────────────
# These are created after the ALB is provisioned by the LB controller.
# Uncomment and run terraform apply again after ALB hostnames are available.

# resource "aws_route53_record" "app" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "app.teamcsolutions.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = ["YOUR_ALB_HOSTNAME"]
# }

# resource "aws_route53_record" "api" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "api.teamcsolutions.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = ["YOUR_ALB_HOSTNAME"]
# }

# resource "aws_route53_record" "jenkins" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "jenkins.teamcsolutions.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = ["YOUR_JENKINS_LB_HOSTNAME"]
# }

# resource "aws_route53_record" "argocd" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "argocd.teamcsolutions.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = ["YOUR_ARGOCD_LB_HOSTNAME"]
# }

# resource "aws_route53_record" "grafana" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "grafana.teamcsolutions.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = ["YOUR_GRAFANA_LB_HOSTNAME"]
# }
