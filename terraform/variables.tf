variable "project_name" {
  description = "Project name — used for naming all AWS resources"
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "Primary AWS region (ap-southeast-1 = Singapore, closest to Vietnam)"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Custom domain name (optional). Leave empty to use the default CloudFront domain"
  type        = string
  default     = ""
}

variable "include_www_alias" {
  description = "When domain_name is set, also add www.<domain_name> as CloudFront alias and ACM SAN"
  type        = bool
  default     = true
}

variable "create_acm_certificate" {
  description = "Create ACM certificate in us-east-1 for CloudFront (DNS validation still needs DNS records)"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "Existing ACM certificate ARN in us-east-1. Leave empty to let Terraform create one"
  type        = string
  default     = ""
}

variable "use_acm_for_cloudfront" {
  description = "Attach custom domain + ACM certificate to CloudFront. Enable after DNS validation is complete"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable WAF on CloudFront — adds ~$7-10/month but protects against spam & bots"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Enable Lambda API placeholder in VPC — free tier but not needed for pure static React"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes per IP (WAF rate limiting)"
  type        = number
  default     = 500
}
