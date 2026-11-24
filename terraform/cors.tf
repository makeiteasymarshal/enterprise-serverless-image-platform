resource "aws_s3_bucket_cors_configuration" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}
