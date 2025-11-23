terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# ==================== Phase 1: Storage ====================
module "storage" {
  source = "../../modules/storage"

  project_name           = var.project_name
  environment            = var.environment
  region                 = var.region
  archive_retention_days = var.archive_retention_days
  cors_allowed_origins   = ["*"]
  
  tags = var.tags
}

# Data source for account ID
data "aws_caller_identity" "current" {}

# ==================== Phase 2: Network ====================
module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  region             = var.region
  create_vpc         = false
  allowed_rtmp_cidrs = var.allowed_rtmp_cidrs
  
  tags = var.tags
}

# ==================== Phase 3: IAM ====================
module "iam" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  archive_bucket_arn = module.storage.archive_bucket_arn
  hls_bucket_arn     = module.storage.hls_bucket_arn
  
  create_lambda_role      = true
  create_eventbridge_role = false
  
  tags = var.tags

  depends_on = [module.storage]
}

# ==================== Phase 4: MediaLive ====================
module "medialive" {
  source = "../../modules/medialive"

  project_name = var.project_name
  environment  = var.environment
  
  # IAM
  iam_role_arn = module.iam.medialive_role_arn
  
  # Network
  security_group_id = module.network.security_group_id
  
  # S3 HLS Output
  hls_bucket_name = module.storage.hls_bucket_name
  
  # S3 Archive
  enable_archive      = var.enable_archive
  archive_bucket_name = module.storage.archive_bucket_name
  
  # 채널 설정
  video_quality = var.video_quality
  channel_class = var.channel_class
  
  tags = var.tags

  depends_on = [module.iam, module.storage]
}

# ==================== Phase 5: Automation ====================
module "automation" {
  source = "../../modules/automation"

  project_name = var.project_name
  environment  = var.environment
  
  # IAM Role
  lambda_role_arn = module.iam.lambda_role_arn
  
  # MediaLive 채널
  medialive_channel_id = module.medialive.channel_id
  
  # 스케줄 설정
  enable_schedule              = var.enable_automation_schedule
  schedule_enabled             = var.schedule_enabled
  start_schedule               = var.start_schedule
  stop_schedule                = var.stop_schedule
  enable_error_notifications   = var.enable_automation_error_notifications
  error_notification_email     = var.automation_error_email
  log_retention_days           = var.automation_log_retention_days
  
  tags = var.tags

  depends_on = [module.medialive, module.iam]
}

# ==================== Phase 6: CloudFront ====================

# CloudFront OAC for S3
resource "aws_cloudfront_origin_access_control" "hls" {
  name                              = "${var.project_name}-${var.environment}-hls-oac"
  description                       = "OAC for HLS S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "player" {
  name                              = "${var.project_name}-${var.environment}-player-oac"
  description                       = "OAC for Player S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for HLS
resource "aws_cloudfront_distribution" "hls" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} HLS Distribution"
  price_class         = "PriceClass_200"  # 아시아, 유럽, 미국
  http_version        = "http2and3"

  origin {
    domain_name              = module.storage.hls_bucket_domain
    origin_id                = "hls-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.hls.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "hls-s3-origin"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 10
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# CloudFront Distribution for Player
resource "aws_cloudfront_distribution" "player" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} Player Distribution"
  price_class         = "PriceClass_200"
  http_version        = "http2and3"
  default_root_object = "index.html"

  origin {
    domain_name              = module.storage.player_bucket_domain
    origin_id                = "player-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.player.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "player-s3-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# S3 Bucket Policy for CloudFront OAC - HLS
resource "aws_s3_bucket_policy" "hls_cloudfront" {
  bucket = module.storage.hls_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.storage.hls_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.hls.arn
          }
        }
      },
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.storage.hls_bucket_arn}/*"
      }
    ]
  })

  depends_on = [
    module.storage,
    aws_cloudfront_distribution.hls
  ]
}

# S3 Bucket Policy for CloudFront OAC - Player
resource "aws_s3_bucket_policy" "player_cloudfront" {
  bucket = module.storage.player_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.storage.player_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.player.arn
          }
        }
      },
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.storage.player_bucket_arn}/*"
      }
    ]
  })

  depends_on = [
    module.storage,
    aws_cloudfront_distribution.player
  ]
}

# HTML 업데이트 (CloudFront 배포 후)
resource "null_resource" "update_player_html" {
  depends_on = [
    aws_cloudfront_distribution.hls,
    module.storage
  ]

  triggers = {
    cloudfront_domain = aws_cloudfront_distribution.hls.domain_name
  }

provisioner "local-exec" {
  command = <<-EOT
    echo const CLOUDFRONT_HLS_URL = "https://${aws_cloudfront_distribution.hls.domain_name}/live.m3u8"; > cloudfront-config.js
    aws s3 cp cloudfront-config.js s3://${module.storage.player_bucket_id}/cloudfront-config.js --content-type "application/javascript"
    del cloudfront-config.js
  EOT
  }
}