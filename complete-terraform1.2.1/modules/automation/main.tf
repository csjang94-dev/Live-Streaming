terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Lambda 함수 코드 (Python)
data "archive_file" "lambda_channel_control" {
  type        = "zip"
  output_path = "${path.module}/lambda_channel_control.zip"

  source {
    content  = <<-EOF
import json
import boto3
import os

medialive = boto3.client('medialive')
channel_id = os.environ['CHANNEL_ID']

def lambda_handler(event, context):
    """
    MediaLive 채널 시작/중지 제어
    """
    action = event.get('action', 'status')
    
    try:
        # 현재 상태 확인
        response = medialive.describe_channel(ChannelId=channel_id)
        current_state = response['State']
        
        print(f"Current channel state: {current_state}")
        
        if action == 'start':
            if current_state in ['IDLE', 'STOPPED']:
                medialive.start_channel(ChannelId=channel_id)
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Channel start initiated',
                        'channelId': channel_id,
                        'previousState': current_state
                    })
                }
            else:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': f'Channel already in {current_state} state',
                        'channelId': channel_id
                    })
                }
        
        elif action == 'stop':
            if current_state in ['RUNNING', 'STARTING']:
                medialive.stop_channel(ChannelId=channel_id)
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Channel stop initiated',
                        'channelId': channel_id,
                        'previousState': current_state
                    })
                }
            else:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': f'Channel already in {current_state} state',
                        'channelId': channel_id
                    })
                }
        
        else:  # status
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'channelId': channel_id,
                    'state': current_state,
                    'arn': response['Arn'],
                    'name': response['Name']
                })
            }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'channelId': channel_id
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda 함수
resource "aws_lambda_function" "channel_control" {
  filename         = data.archive_file.lambda_channel_control.output_path
  function_name    = "${var.project_name}-${var.environment}-channel-control"
  role            = var.lambda_role_arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_channel_control.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      CHANNEL_ID = var.medialive_channel_id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-channel-control"
    }
  )
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.channel_control.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# EventBridge Rule - 시작 스케줄
resource "aws_cloudwatch_event_rule" "start_schedule" {
  count = var.enable_schedule ? 1 : 0

  name                = "${var.project_name}-${var.environment}-start-schedule"
  description         = "Automatically start MediaLive channel"
  schedule_expression = var.start_schedule
  is_enabled          = var.schedule_enabled

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-start-schedule"
    }
  )
}

# EventBridge Target - 시작
resource "aws_cloudwatch_event_target" "start_lambda" {
  count = var.enable_schedule ? 1 : 0

  rule      = aws_cloudwatch_event_rule.start_schedule[0].name
  target_id = "StartMediaLive"
  arn       = aws_lambda_function.channel_control.arn

  input = jsonencode({
    action = "start"
  })
}

# Lambda Permission for EventBridge - 시작
resource "aws_lambda_permission" "allow_eventbridge_start" {
  count = var.enable_schedule ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.channel_control.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule[0].arn
}

# EventBridge Rule - 중지 스케줄
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  count = var.enable_schedule ? 1 : 0

  name                = "${var.project_name}-${var.environment}-stop-schedule"
  description         = "Automatically stop MediaLive channel"
  schedule_expression = var.stop_schedule
  is_enabled          = var.schedule_enabled

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-stop-schedule"
    }
  )
}

# EventBridge Target - 중지
resource "aws_cloudwatch_event_target" "stop_lambda" {
  count = var.enable_schedule ? 1 : 0

  rule      = aws_cloudwatch_event_rule.stop_schedule[0].name
  target_id = "StopMediaLive"
  arn       = aws_lambda_function.channel_control.arn

  input = jsonencode({
    action = "stop"
  })
}

# Lambda Permission for EventBridge - 중지
resource "aws_lambda_permission" "allow_eventbridge_stop" {
  count = var.enable_schedule ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.channel_control.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule[0].arn
}

# SNS Topic for Lambda Errors
resource "aws_sns_topic" "lambda_errors" {
  count = var.enable_error_notifications ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-errors"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-errors"
    }
  )
}

# SNS Subscription
resource "aws_sns_topic_subscription" "lambda_errors_email" {
  count = var.enable_error_notifications && var.error_notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.lambda_errors[0].arn
  protocol  = "email"
  endpoint  = var.error_notification_email
}

# CloudWatch Alarm - Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.enable_error_notifications ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda function has errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.channel_control.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_errors[0].arn]
}

# CloudWatch Alarm - Lambda Throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count = var.enable_error_notifications ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda function is being throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.channel_control.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_errors[0].arn]
}

# CloudWatch Event Rule - 실패 알림
resource "aws_cloudwatch_event_rule" "lambda_failure" {
  count = var.enable_error_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-lambda-failure"
  description = "Capture Lambda execution failures"

  event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["Lambda Function Execution State Change"]
    detail = {
      functionName = [aws_lambda_function.channel_control.function_name]
      status       = ["Failed"]
    }
  })

  tags = var.tags
}

# EventBridge Target - 실패 알림
resource "aws_cloudwatch_event_target" "lambda_failure_sns" {
  count = var.enable_error_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.lambda_failure[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.lambda_errors[0].arn
}
