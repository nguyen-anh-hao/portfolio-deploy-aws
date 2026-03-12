output "bucket_id" {
  description = "S3 bucket ID (name)"
  value       = aws_s3_bucket.react_app.id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.react_app.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.react_app.arn
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name (for CloudFront origin)"
  value       = aws_s3_bucket.react_app.bucket_regional_domain_name
}
