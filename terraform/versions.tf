terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote State (Production): uncomment after bootstrapping an S3 bucket + lock table
  # backend "s3" {
  #   bucket       = "my-terraform-state-bucket-unique-id"
  #   key          = "baseline/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Alignment   = "NCA-CSCC"
    }
  }
}