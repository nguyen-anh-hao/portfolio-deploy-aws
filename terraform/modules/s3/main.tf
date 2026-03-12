# Random suffix to ensure globally unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ── S3 Bucket (private — accessed only via CloudFront OAC) ───────────────────

resource "aws_s3_bucket" "react_app" {
  bucket = "${var.project_name}-${var.environment}-app-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-react-app"
  }
}

# Block all public access — CloudFront OAC handles access
resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning — allows rollback to previous React builds
resource "aws_s3_bucket_versioning" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt bucket at rest (free with AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle: auto-delete old versions after 30 days to save storage cost
resource "aws_s3_bucket_lifecycle_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {} # required by AWS provider >= 4.x

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.react_app]
}
