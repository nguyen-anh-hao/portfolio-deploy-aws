output "waf_acl_arn" {
  description = "WAF Web ACL ARN to attach to CloudFront (null if WAF disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}
