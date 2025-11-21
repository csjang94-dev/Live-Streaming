terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket for Archive
resource "aws_s3_bucket" "archive" {
  bucket = "${var.project_name}-${var.environment}-archive-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-archive"
      Purpose = "MediaLive Archive Storage"
    }
  )
}

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "archive" {
  bucket = aws_s3_bucket.archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Rule - 오래된 파일 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    id     = "delete-old-archives"
    status = "Enabled"

    expiration {
      days = var.archive_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

# CORS Configuration (CloudFront에서 접근 가능하도록)
resource "aws_s3_bucket_cors_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
