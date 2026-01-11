terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "claude-codespaces-aws-s3-hello-world-tfstate"
    key            = "website/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "claude-codespaces-aws-s3-hello-world-tflock"
    encrypt        = true
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
