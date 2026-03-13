# Random suffix for globally unique S3 bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ── VPC ───────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ── S3 (React static files) ───────────────────────────────────────────────────

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# ── WAF (must be in us-east-1 for CloudFront) ────────────────────────────────

module "waf" {
  source = "./modules/waf"

  providers = {
    aws = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  enable_waf   = var.enable_waf
  rate_limit   = var.waf_rate_limit
}

# ── ACM Certificate (us-east-1, required by CloudFront) ─────────────────────

locals {
  custom_domain_enabled         = var.domain_name != ""
  requested_subject_alt_names   = var.include_www_alias && var.domain_name != "" ? ["www.${var.domain_name}"] : []
  cloudfront_acm_certificate_arn = var.use_acm_for_cloudfront ? (
    var.acm_certificate_arn != "" ? var.acm_certificate_arn : (
      var.create_acm_certificate && local.custom_domain_enabled ? aws_acm_certificate.cloudfront[0].arn : ""
    )
  ) : ""
  cloudfront_domain_name = local.cloudfront_acm_certificate_arn != "" ? var.domain_name : ""
  cloudfront_include_www_alias = local.cloudfront_domain_name != "" ? var.include_www_alias : false
}

resource "aws_acm_certificate" "cloudfront" {
  count = var.create_acm_certificate && local.custom_domain_enabled && var.acm_certificate_arn == "" ? 1 : 0

  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = local.requested_subject_alt_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-cert"
  }
}

# ── CloudFront (CDN + SPA routing + WAF) ─────────────────────────────────────

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name        = var.project_name
  environment         = var.environment
  s3_bucket_id        = module.s3.bucket_id
  s3_bucket_arn       = module.s3.bucket_arn
  s3_bucket_domain    = module.s3.bucket_regional_domain_name
  waf_acl_arn         = module.waf.waf_acl_arn
  domain_name         = local.cloudfront_domain_name
  include_www_alias   = local.cloudfront_include_www_alias
  acm_certificate_arn = local.cloudfront_acm_certificate_arn
}

# ── Lambda (API placeholder — in VPC, ready for future DB connection) ─────────
# Bật bằng cách set enable_lambda = true trong terraform.tfvars

module "lambda" {
  count  = var.enable_lambda ? 1 : 0
  source = "./modules/lambda"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

# ── IAM user for CI/CD (GitHub Actions) ──────────────────────────────────────

resource "aws_iam_user" "cicd" {
  name = "${var.project_name}-${var.environment}-cicd"

  tags = {
    Name = "${var.project_name}-${var.environment}-cicd"
  }
}

resource "aws_iam_access_key" "cicd" {
  user = aws_iam_user.cicd.name
}

resource "aws_iam_user_policy" "cicd" {
  name = "${var.project_name}-${var.environment}-cicd-policy"
  user = aws_iam_user.cicd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow uploading React build files to S3
        Sid    = "S3DeployAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          module.s3.bucket_arn,
          "${module.s3.bucket_arn}/*",
        ]
      },
      {
        # Allow CloudFront cache invalidation after deploy
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = [module.cloudfront.distribution_arn]
      },
    ]
  })
}
