# S3 Bucket for Static Website Hosting

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name = "Static Website"
  }
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Allow public access for website
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# Upload website files
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "../../website/index.html"
  content_type = "text/html"
  etag         = filemd5("../../website/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "../../website/error.html"
  content_type = "text/html"
  etag         = filemd5("../../website/error.html")
}

resource "aws_s3_object" "styles" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  source       = "../../website/styles.css"
  content_type = "text/css"
  etag         = filemd5("../../website/styles.css")
}

# CloudWatch Log Group for website access logging
resource "aws_cloudwatch_log_group" "website" {
  name              = "/aws/s3/${var.bucket_name}"
  retention_in_days = 7

  tags = {
    Name = "Website Access Logs"
  }
}
