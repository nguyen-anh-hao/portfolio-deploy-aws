# ── Origin Access Control (OAC) ───────────────────────────────────────────────
# OAC is the modern/recommended replacement for OAI
# Allows CloudFront to securely read from private S3 bucket

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} React App S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CloudFront Distribution ───────────────────────────────────────────────────

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.project_name}-${var.environment} React SPA"
  web_acl_id          = var.waf_acl_arn

  # PriceClass_100 = US + EU edge locations (cheapest)
  # Change to PriceClass_200 or PriceClass_All for Asia-Pacific coverage
  price_class = "PriceClass_100"

  aliases = var.domain_name != "" ? concat([var.domain_name], var.include_www_alias ? ["www.${var.domain_name}"] : []) : []

  # ── S3 Origin ──────────────────────────────────────────────────────────────
  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = "s3-react-app"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # ── Default Cache Behaviour ────────────────────────────────────────────────
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-react-app"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  }

  # ── SPA Routing Fix ────────────────────────────────────────────────────────
  # React Router needs this: 404/403 from S3 → serve index.html → React handles routing
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == ""
    acm_certificate_arn            = var.domain_name != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }
}

# ── S3 Bucket Policy: allow CloudFront OAC to read ───────────────────────────

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    sid    = "AllowCloudFrontOACReadAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    # Restrict access to THIS specific CloudFront distribution only
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}
