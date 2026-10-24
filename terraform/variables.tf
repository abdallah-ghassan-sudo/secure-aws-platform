variable "aws_region" {
  description = "AWS Deployment Region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2", "eu-west-1", "me-central-1"], var.aws_region)
    error_message = "Region must be an approved deployment region (us-east-1, us-west-2, eu-west-1, me-central-1)."
  }
}

variable "project_name" {
  description = "Project name used for resource tagging and naming"
  type        = string
  default     = "secure-aws-platform"
}

variable "environment" {
  description = "Deployment environment (security-lab, staging, or production)"
  type        = string
  default     = "security-lab"

  validation {
    condition     = contains(["security-lab", "staging", "production"], var.environment)
    error_message = "Environment must be one of: security-lab, staging, production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the baseline VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The vpc_cidr value must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to slice dynamically from available zones in the region"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 for high availability."
  }
}

variable "alert_email" {
  description = "Email address to receive critical CloudWatch/SNS security alerts (optional in lab, set in tfvars)"
  type        = string
  default     = null

  validation {
    condition     = var.alert_email == null || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "If provided, alert_email must be a valid email address."
  }
}