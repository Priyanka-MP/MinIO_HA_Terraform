# providers.tf
# Terraform and provider configuration
# This file defines the required Terraform version and AWS provider configuration
# for the MinIO High Availability deployment

# Terraform version constraint - ensures compatibility and stability
# Version 1.5.0+ is required for the features used in this configuration
terraform {
  required_version = ">= 1.5.0"

  # Required providers with version constraints
  # AWS provider for cloud resources, Random provider for credential generation
  required_providers {
    # AWS provider - main cloud provider for all AWS resources
    # Version ~> 5.55 ensures we get the latest 5.x version with bug fixes
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }

    # Random provider - used for generating MinIO root credentials
    # Version ~> 3.6 provides stable random string generation
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# AWS provider configuration
# Sets the default region for all AWS resources
# The region is configurable via the 'region' variable
provider "aws" {
  region = var.region
}
