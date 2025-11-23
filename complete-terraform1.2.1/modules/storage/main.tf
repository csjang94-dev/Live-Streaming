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

# ==============================================
# S3 Bucket for Web Player Hosting
# ==============================================
resource "aws_s3_bucket" "player" {
  bucket = "${var.project_name}-${var.environment}-player-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-player"
      Purpose = "Web Player Hosting"
    }
  )
}

# Player Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "player" {
  bucket = aws_s3_bucket.player.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Player Bucket Public Access
resource "aws_s3_bucket_public_access_block" "player" {
  bucket = aws_s3_bucket.player.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Player Bucket Policy
resource "aws_s3_bucket_policy" "player" {
  depends_on = [aws_s3_bucket_public_access_block.player]
  
  bucket = aws_s3_bucket.player.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.player.arn}/*"
      }
    ]
  })
}

# Player HTML Upload
resource "aws_s3_object" "player_html" {
  bucket       = aws_s3_bucket.player.id
  key          = "index.html"
  content      = templatefile("${path.module}/../../player/index.html.tpl", {
    BUCKET_NAME = aws_s3_bucket.hls.id
    REGION      = var.region
  })
  content_type = "text/html"
  etag         = md5(templatefile("${path.module}/../../player/index.html.tpl", {
    BUCKET_NAME = aws_s3_bucket.hls.id
    REGION      = var.region
  }))
}
