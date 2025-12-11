# AWS DevOps Agent Terraform Configuration
# This configuration replicates the CLI onboarding guide setup

provider "awscc" {
  region = var.aws_region
}

provider "aws" {
  region = var.aws_region
}

# Provider aliases for external accounts (configure these with assume_role if needed)
# Example configuration in terraform.tfvars:
# external_accounts = {
#   "123456789012" = {
#     account_id = "123456789012"
#     role_arn   = "arn:aws:iam::123456789012:role/OrganizationAccountAccessRole"
#   }
# }

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}