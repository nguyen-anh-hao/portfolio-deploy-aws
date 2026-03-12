# NOTE: This module MUST use the us-east-1 provider.
# CloudFront WAF Web ACLs must be in us-east-1 — this is an AWS hard requirement.
# Provider is passed from root module via: providers = { aws = aws.us_east_1 }

# ── WAF Web ACL ───────────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "${var.project_name}-${var.environment}-waf"
  description = "WAF for ${var.project_name} CloudFront distribution"
  scope       = "CLOUDFRONT" # MUST be us-east-1

  default_action {
    allow {}
  }

  # ── Rule 1: Rate Limiting ───────────────────────────────────────────────────
  # Block IPs sending more than N requests per 5 minutes
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 2: AWS Managed Rules — Common Rule Set (free) ─────────────────────
  # Protects against OWASP Top 10: SQL injection, XSS, etc.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {} # Use default actions from managed rule group
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 3: AWS Managed Rules — IP Reputation List (free) ──────────────────
  # Block known malicious IPs (botnets, scanners, etc.)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-waf"
  }
}
