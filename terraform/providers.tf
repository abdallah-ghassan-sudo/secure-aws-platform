provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "secure-aws-platform"
      Environment = "learning"
      ManagedBy   = "Terraform"
    }
  }
}