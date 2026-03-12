variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID (name) to set bucket policy on"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for bucket policy"
  type        = string
}

variable "s3_bucket_domain" {
  description = "S3 bucket regional domain name (origin for CloudFront)"
  type        = string
}

variable "waf_acl_arn" {
  description = "WAF Web ACL ARN to attach (null to disable WAF)"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
  default     = ""
}

# Uncomment when adding custom domain:
# variable "acm_certificate_arn" {
#   description = "ACM certificate ARN (must be in us-east-1)"
#   type        = string
#   default     = ""
# }
