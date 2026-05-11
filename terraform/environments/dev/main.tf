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