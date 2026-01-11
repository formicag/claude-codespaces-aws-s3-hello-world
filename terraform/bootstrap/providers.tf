terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "claude-codespaces-aws-s3-hello-world"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
