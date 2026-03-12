output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.api.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.api.arn
}

output "function_url" {
  description = "Lambda Function URL (HTTPS endpoint — no API Gateway needed)"
  value       = aws_lambda_function_url.api.function_url
}

output "security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "iam_role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.lambda.arn
}
