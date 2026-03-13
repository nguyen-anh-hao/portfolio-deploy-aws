# ── App URL ───────────────────────────────────────────────────────────────────

output "app_url" {
  description = "Public URL to access the React app"
  value       = "https://${module.cloudfront.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.cloudfront.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — add to GitHub Secrets as CLOUDFRONT_DISTRIBUTION_ID"
  value       = module.cloudfront.distribution_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used by CloudFront (us-east-1)"
  value       = local.cloudfront_acm_certificate_arn != "" ? local.cloudfront_acm_certificate_arn : "(No custom domain certificate configured)"
}

output "acm_dns_validation_records" {
  description = "Add these CNAME records in your DNS provider (Cloudflare) to validate ACM"
  value = length(aws_acm_certificate.cloudfront) > 0 ? [
    for option in aws_acm_certificate.cloudfront[0].domain_validation_options : {
      domain_name  = option.domain_name
      record_name  = option.resource_record_name
      record_type  = option.resource_record_type
      record_value = option.resource_record_value
    }
  ] : []
}

# ── S3 ────────────────────────────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "S3 bucket name — add to GitHub Secrets as S3_BUCKET_NAME"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

# ── VPC ───────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ── Lambda ────────────────────────────────────────────────────────────────────

output "lambda_function_url" {
  description = "Lambda Function URL (API endpoint — free, no API Gateway)"
  value       = var.enable_lambda ? module.lambda[0].function_url : "(Lambda disabled — set enable_lambda = true to activate)"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = var.enable_lambda ? module.lambda[0].function_name : null
}

# ── CI/CD Credentials ─────────────────────────────────────────────────────────

output "cicd_access_key_id" {
  description = "IAM Access Key ID — add to GitHub Secrets as AWS_ACCESS_KEY_ID"
  value       = aws_iam_access_key.cicd.id
  sensitive   = false
}

output "cicd_secret_access_key" {
  description = "IAM Secret Access Key — add to GitHub Secrets as AWS_SECRET_ACCESS_KEY"
  value       = aws_iam_access_key.cicd.secret
  sensitive   = true
}

# ── Setup Summary ─────────────────────────────────────────────────────────────

output "setup_instructions" {
  description = "Next steps for CI/CD setup"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════╗
    ║              CI/CD GitHub Secrets Setup                     ║
    ╚══════════════════════════════════════════════════════════════╝

    In your React repo: Settings → Secrets and variables → Actions
    Add these secrets:

      AWS_ACCESS_KEY_ID            = ${aws_iam_access_key.cicd.id}
      AWS_SECRET_ACCESS_KEY        = (run: terraform output -raw cicd_secret_access_key)
      S3_BUCKET_NAME               = ${module.s3.bucket_name}
      CLOUDFRONT_DISTRIBUTION_ID   = ${module.cloudfront.distribution_id}
      AWS_REGION                   = ${var.aws_region}

    Then copy github-actions/workflows/*.yml to your React repo's .github/workflows/

    App URL: https://${module.cloudfront.domain_name}
  EOT
}
