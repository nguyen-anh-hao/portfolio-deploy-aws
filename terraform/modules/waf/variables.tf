terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "enable_waf" {
  description = "Enable WAF Web ACL"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Max requests per 5 minutes per IP before blocking"
  type        = number
  default     = 500
}
