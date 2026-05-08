terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.0"  }
    random     = { source = "hashicorp/random",     version = "~> 3.0"  }
    tls        = { source = "hashicorp/tls",        version = "~> 4.0"  }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.27" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.13" }
  }
  backend "s3" {
    bucket         = "shopsecure-terraform-state-887998956998"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopsecure-terraform-locks"
    encrypt        = true
  }
}

provider "aws" { region = "us-east-1" }

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
  common_tags = {
    Project     = "shopsecure"
    Environment = "dev"
    ManagedBy   = "terraform"
    Domain      = "dev.teamcsolutions.com"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  project            = "shopsecure"
  environment        = "dev"
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  common_tags        = local.common_tags
}

module "eks" {
  source             = "../../modules/eks"
  project            = "shopsecure"
  environment        = "dev"
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  common_tags        = local.common_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  project     = "shopsecure"
  environment = "dev"
  common_tags = local.common_tags
}
