terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version = "6.34.0"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
  #   access_key = 
  #   secret_key = 

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}