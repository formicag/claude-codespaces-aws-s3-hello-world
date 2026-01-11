output "website_url" {
  description = "URL of the static website"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for website"
  value       = aws_cloudwatch_log_group.website.name
}
