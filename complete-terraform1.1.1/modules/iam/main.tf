terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# MediaLive에서 사용할 IAM Role
resource "aws_iam_role" "medialive" {
  name = "${var.project_name}-${var.environment}-medialive-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "medialive.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-medialive-role"
    }
  )
}

# MediaLive Role Policy - MediaPackage 접근
resource "aws_iam_role_policy" "medialive_mediapackage" {
  name = "mediapackage-access"
  role = aws_iam_role.medialive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mediapackage:DescribeChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# MediaLive Role Policy - S3 Full Access
resource "aws_iam_role_policy" "medialive_s3" {
  name = "s3-access"
  role = aws_iam_role.medialive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"  # S3 Full Access
        ]
        Resource = [
          var.archive_bucket_arn,
          "${var.archive_bucket_arn}/*",
          var.hls_bucket_arn,
          "${var.hls_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Lambda에서 사용할 IAM Role (Phase 7에서 사용)
resource "aws_iam_role" "lambda" {
  count = var.create_lambda_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-role"
    }
  )
}

# Lambda Role Policy - MediaLive 제어
resource "aws_iam_role_policy" "lambda_medialive" {
  count = var.create_lambda_role ? 1 : 0

  name = "medialive-control"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "medialive:StartChannel",
          "medialive:StopChannel",
          "medialive:DescribeChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Role Policy - CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs" {
  count = var.create_lambda_role ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# EventBridge에서 사용할 IAM Role (Phase 7에서 사용)
resource "aws_iam_role" "eventbridge" {
  count = var.create_eventbridge_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eventbridge-role"
    }
  )
}

# EventBridge Role Policy - Lambda 호출
resource "aws_iam_role_policy" "eventbridge_lambda" {
  count = var.create_eventbridge_role ? 1 : 0

  name = "lambda-invoke"
  role = aws_iam_role.eventbridge[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}
