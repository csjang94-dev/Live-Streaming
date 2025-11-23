terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "mediapackage" {
  name                              = "${var.project_name}-${var.environment}-mediapackage-oac"
  description                       = "OAC for MediaPackage origin"
  origin_access_control_origin_type = "mediapackage"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} Live Streaming Distribution"
  price_class         = var.price_class
  http_version        = "http2and3"
  
  # Custom Domain (선택사항)
  aliases = var.custom_domain != "" ? [var.custom_domain] : []

  # Origin - MediaPackage
  origin {
    domain_name = var.mediapackage_domain
    origin_id   = "mediapackage-origin"
    origin_path = var.mediapackage_path

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 30
      origin_keepalive_timeout = 5
    }

    # MediaPackage CDN Identifier
    custom_header {
      name  = "X-MediaPackage-CDNIdentifier"
      value = random_string.cdn_identifier.result
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = "mediapackage-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    # Cache Policy
    cache_policy_id = var.enable_custom_cache_policy ? aws_cloudfront_cache_policy.hls[0].id : data.aws_cloudfront_cache_policy.caching_optimized.id

    # Origin Request Policy
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_custom_origin.id

    # Response Headers Policy (CORS)
    response_headers_policy_id = var.enable_cors ? aws_cloudfront_response_headers_policy.cors[0].id : null
  }

  # Cache Behavior for .m3u8 (Manifest)
  ordered_cache_behavior {
    path_pattern           = "*.m3u8"
    target_origin_id       = "mediapackage-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    # Manifest는 짧은 TTL
    cache_policy_id = aws_cloudfront_cache_policy.manifest.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_custom_origin.id
    response_headers_policy_id = var.enable_cors ? aws_cloudfront_response_headers_policy.cors[0].id : null
  }

  # Cache Behavior for .ts (Segments)
  ordered_cache_behavior {
    path_pattern           = "*.ts"
    target_origin_id       = "mediapackage-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Segment는 긴 TTL
    cache_policy_id = aws_cloudfront_cache_policy.segments.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_custom_origin.id
  }

  # Geo Restriction (선택사항)
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.custom_domain == "" ? true : false
    acm_certificate_arn           = var.custom_domain != "" ? var.acm_certificate_arn : null
    ssl_support_method            = var.custom_domain != "" ? "sni-only" : null
    minimum_protocol_version      = "TLSv1.2_2021"
  }

  # Logging (선택사항)
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logging_bucket_domain_name
      prefix          = var.logging_prefix
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-distribution"
    }
  )
}

# Random CDN Identifier for MediaPackage
resource "random_string" "cdn_identifier" {
  length  = 16
  special = false
  upper   = false
}

# Cache Policy - Manifest (.m3u8)
resource "aws_cloudfront_cache_policy" "manifest" {
  name        = "${var.project_name}-${var.environment}-manifest-policy"
  comment     = "Cache policy for HLS manifests"
  default_ttl = 2
  max_ttl     = 5
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Cache Policy - Segments (.ts)
resource "aws_cloudfront_cache_policy" "segments" {
  name        = "${var.project_name}-${var.environment}-segments-policy"
  comment     = "Cache policy for HLS segments"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 60

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Cache Policy - Custom HLS (선택사항)
resource "aws_cloudfront_cache_policy" "hls" {
  count = var.enable_custom_cache_policy ? 1 : 0

  name        = "${var.project_name}-${var.environment}-hls-policy"
  comment     = "Custom cache policy for HLS streaming"
  default_ttl = 10
  max_ttl     = 30
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Response Headers Policy - CORS
resource "aws_cloudfront_response_headers_policy" "cors" {
  count = var.enable_cors ? 1 : 0

  name    = "${var.project_name}-${var.environment}-cors-policy"
  comment = "CORS policy for HLS streaming"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = var.cors_allowed_origins
    }

    access_control_expose_headers {
      items = ["*"]
    }

    access_control_max_age_sec = 3600
    origin_override            = true
  }

  # Security Headers
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# AWS Managed Cache Policies (참조용)
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_custom_origin" {
  name = "Managed-CORS-CustomOrigin"
}

# CloudWatch Alarm - 4xx Error Rate (선택사항)
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront 4xx error rate is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}

# CloudWatch Alarm - 5xx Error Rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CloudFront 5xx error rate is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}
