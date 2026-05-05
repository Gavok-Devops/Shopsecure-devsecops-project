terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws    = { source = "hashicorp/aws",    version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    tls    = { source = "hashicorp/tls",    version = "~> 4.0" }
  }
  backend "s3" {
    bucket         = "shopsecure-terraform-state-ACCOUNT_ID"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopsecure-terraform-locks"
    encrypt        = true
  }
}

provider "aws" { region = "us-east-1" }

locals {
  common_tags = {
    Project     = "shopsecure"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  project            = "shopsecure"
  environment        = "staging"
  vpc_cidr           = "10.2.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  common_tags        = local.common_tags
}

module "eks" {
  source             = "../../modules/eks"
  project            = "shopsecure"
  environment        = "staging"
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  common_tags        = local.common_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  project     = "shopsecure"
  environment = "staging"
  common_tags = local.common_tags
}

module "rds" {
  source                    = "../../modules/rds"
  project                   = "shopsecure"
  environment               = "staging"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  allowed_security_group_ids = []
  instance_class            = "db.t3.medium"
  multi_az                  = false
  common_tags               = local.common_tags
}
