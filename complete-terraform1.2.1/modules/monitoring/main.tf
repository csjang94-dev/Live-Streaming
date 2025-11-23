terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-live-streaming"

  dashboard_body = jsonencode({
    widgets = [
      # MediaLive 섹션
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/MediaLive", "InputVideoFrameRate", { stat = "Average", label = "Input Frame Rate" }],
            [".", "OutputVideoFrameRate", { stat = "Average", label = "Output Frame Rate" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "MediaLive - Frame Rate"
          period  = 60
          yAxis = {
            left = {
              min = 0
              max = 60
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/MediaLive", "ActiveOutputs", { stat = "Average" }],
            [".", "DroppedFrames", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "MediaLive - Status & Errors"
          period  = 60
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/MediaLive", "OutputBitrate", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "MediaLive - Bitrate"
          period  = 60
          yAxis = {
            left = {
              label = "bps"
            }
          }
        }
      },

      # MediaPackage 섹션
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/MediaPackage", "EgressBytes", { stat = "Sum", label = "Egress" }],
            [".", "IngressBytes", { stat = "Sum", label = "Ingress" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "MediaPackage - Data Transfer"
          period  = 300
          yAxis = {
            left = {
              label = "Bytes"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/MediaPackage", "EgressRequestCount", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "MediaPackage - Requests"
          period  = 300
        }
      },

      # CloudFront 섹션
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", { stat = "Sum", region = "us-east-1" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront - Requests"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", { stat = "Sum", region = "us-east-1" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront - Bytes Downloaded"
          period  = 300
          yAxis = {
            left = {
              label = "Bytes"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", { stat = "Average", region = "us-east-1" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront - Cache Hit Rate"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "%"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", { stat = "Average", region = "us-east-1", color = "#ff7f0e" }],
            [".", "5xxErrorRate", { stat = "Average", region = "us-east-1", color = "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront - Error Rates"
          period  = 300
          yAxis = {
            left = {
              min = 0
              label = "%"
            }
          }
        }
      }
    ]
  })
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alarms"
    }
  )
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# MediaLive Alarms
resource "aws_cloudwatch_metric_alarm" "medialive_dropped_frames" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-medialive-dropped-frames"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DroppedFrames"
  namespace           = "AWS/MediaLive"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "MediaLive dropped frames detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ChannelId = var.medialive_channel_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "medialive_active_alerts" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-medialive-active-alerts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ActiveAlerts"
  namespace           = "AWS/MediaLive"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "MediaLive has active alerts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ChannelId = var.medialive_channel_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "medialive_low_framerate" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-medialive-low-framerate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "InputVideoFrameRate"
  namespace           = "AWS/MediaLive"
  period              = 60
  statistic           = "Average"
  threshold           = 25
  alarm_description   = "MediaLive input frame rate is too low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ChannelId = var.medialive_channel_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# CloudFront Alarms
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_error_rate" {
  count = var.enable_alarms && var.cloudfront_distribution_id != "" ? 1 : 0

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
    DistributionId = var.cloudfront_distribution_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_error_rate" {
  count = var.enable_alarms && var.cloudfront_distribution_id != "" ? 1 : 0

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
    DistributionId = var.cloudfront_distribution_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_rate" {
  count = var.enable_alarms && var.cloudfront_distribution_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-low-cache-hit"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CloudFront cache hit rate is below 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Budget Alert (비용 알람)
resource "aws_budgets_budget" "monthly_cost" {
  count = var.enable_budget_alert ? 1 : 0

  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  cost_filters = {
    Service = "AWS Elemental MediaLive"
  }
}

# CloudWatch Log Group for MediaLive (이미 있을 수 있음)
resource "aws_cloudwatch_log_group" "medialive" {
  count             = var.enable_logs ? 1 : 0
  name              = "/aws/medialive/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-medialive-logs"
    }
  )
}
