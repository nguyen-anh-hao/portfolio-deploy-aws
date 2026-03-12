# Package Lambda source code into a zip file
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/index.js"
  output_path = "${path.module}/dist/lambda.zip"
}

# ── IAM Role for Lambda ───────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-role"
  }
}

# VPC access policy (required to place Lambda in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ── Security Group for Lambda ─────────────────────────────────────────────────

resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  description = "Security group for Lambda API functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound (VPC internal only - no NAT)"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  }
}

# ── Lambda Function ───────────────────────────────────────────────────────────

resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.project_name}-${var.environment}-api"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout     = 30  # seconds
  memory_size = 128 # MB — minimum, costs ~$0/month at free tier

  # Deploy Lambda in VPC private subnets
  # NOTE: No NAT Gateway = no external internet from Lambda.
  # Add NAT or VPC Endpoints when Lambda needs external API access.
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_cloudwatch_log_group.lambda,
  ]
}

# ── Lambda Function URL (free — no API Gateway needed for simple use cases) ──
# Access your Lambda directly via HTTPS URL.
# For rate limiting at Lambda level, use WAF with API Gateway instead.

resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE" # Public — add AWS_IAM or JWT auth when needed

  cors {
    allow_credentials = false
    allow_origins     = ["*"] # Restrict to your domain in production
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    max_age           = 300
  }
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api"
  retention_in_days = 14 # 14 days — balance between debugging and cost

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-logs"
  }
}
