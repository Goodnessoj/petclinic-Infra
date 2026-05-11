terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Observability Module
module "observability" {
  source = "../../modules/observability"

  project_name = var.project_name
  environment  = var.environment
}

# GitHub OIDC Module
module "github_oidc" {
  source = "../../modules/github-oidc"
# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  environment = var.environment
}

module "rds" {
  source = "../../modules/rds"

  environment                  = var.environment
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.public_subnet_ids
  eks_security_group_id        = module.vpc.eks_cluster_security_group_id
  eks_node_security_group_id   = module.eks.node_security_group_id    # Dynamic from EKS module
  db_name                      = var.db_name
  db_username                  = var.db_username
  db_instance_class            = var.db_instance_class
  db_allocated_storage         = var.db_allocated_storage
  multi_az                     = var.multi_az
  backup_retention_period      = var.backup_retention_period
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"

  environment = var.environment
  openai_api_key = var.openai_api_key
}
