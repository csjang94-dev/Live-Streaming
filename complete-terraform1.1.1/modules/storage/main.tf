terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}

# ==============================================
# S3 Bucket for HLS (MediaLive 직접 출력)
# ==============================================
resource "aws_s3_bucket" "hls" {
  bucket = "${var.project_name}-${var.environment}-hls-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-hls"
      Purpose = "MediaLive HLS Output"
    }
  )
}

# HLS Bucket Versioning
resource "aws_s3_bucket_versioning" "hls" {
  bucket = aws_s3_bucket.hls.id

  versioning_configuration {
    status = "Disabled"
  }
}

# HLS Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "hls" {
  bucket = aws_s3_bucket.hls.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# HLS Bucket Public Access (CloudFront가 접근 가능하도록)
resource "aws_s3_bucket_public_access_block" "hls" {
  bucket = aws_s3_bucket.hls.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HLS Bucket CORS (CloudFront에서 접근 가능하도록)
resource "aws_s3_bucket_cors_configuration" "hls" {
  bucket = aws_s3_bucket.hls.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# HLS Bucket Lifecycle - 오래된 세그먼트 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "hls" {
  bucket = aws_s3_bucket.hls.id

  rule {
    id     = "delete-old-segments"
    status = "Enabled"

    filter {
      prefix = "live/"
    }

    expiration {
      days = 1  # HLS 세그먼트는 1일 후 삭제
    }
  }
}

# ==============================================
# S3 Bucket for Archive
# ==============================================
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

    filter {}  # 모든 객체에 적용

    expiration {
      days = var.archive_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

# CORS Configuration
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
