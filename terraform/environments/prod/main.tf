terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws    = { source = "hashicorp/aws",    version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    tls    = { source = "hashicorp/tls",    version = "~> 4.0" }
  }

  backend "s3" {
    # Run scripts/bootstrap-backend.sh first, then fill in:
    bucket         = "shopsecure-terraform-state-ACCOUNT_ID"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopsecure-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "shopsecure"
    Environment = "prod"
    ManagedBy   = "terraform"
    Team        = "platform"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  project            = "shopsecure"
  environment        = "prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  common_tags        = local.common_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  project     = "shopsecure"
  environment = "prod"
  common_tags = local.common_tags
}

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

module "rds" {
  source                    = "../../modules/rds"
  project                   = "shopsecure"
  environment               = "prod"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_role_arn]
  instance_class            = "db.m5.large"
  multi_az                  = true
  common_tags               = local.common_tags
}

module "elasticache" {
  source                    = "../../modules/elasticache"
  project                   = "shopsecure"
  environment               = "prod"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  allowed_security_group_ids = []
  node_type                 = "cache.m5.large"
  common_tags               = local.common_tags
}
