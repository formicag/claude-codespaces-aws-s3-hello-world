variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for the static website"
  type        = string
  default     = "claude-codespaces-aws-s3-hello-world-site"
}
