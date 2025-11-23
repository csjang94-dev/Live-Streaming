output "lambda_function_name" {
  description = "Lambda 함수 이름"
  value       = aws_lambda_function.channel_control.function_name
}

output "lambda_function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.channel_control.arn
}

output "start_schedule_expression" {
  description = "시작 스케줄 표현식"
  value       = var.enable_schedule ? var.start_schedule : "Not configured"
}

output "stop_schedule_expression" {
  description = "중지 스케줄 표현식"
  value       = var.enable_schedule ? var.stop_schedule : "Not configured"
}

output "schedule_status" {
  description = "스케줄 상태"
  value       = var.enable_schedule ? (var.schedule_enabled ? "Enabled" : "Disabled") : "Not configured"
}

output "manual_invoke_commands" {
  description = "수동 실행 명령어"
  value = {
    start = "aws lambda invoke --function-name ${aws_lambda_function.channel_control.function_name} --payload '{\"action\": \"start\"}' response.json && cat response.json"
    stop  = "aws lambda invoke --function-name ${aws_lambda_function.channel_control.function_name} --payload '{\"action\": \"stop\"}' response.json && cat response.json"
    status = "aws lambda invoke --function-name ${aws_lambda_function.channel_control.function_name} --payload '{\"action\": \"status\"}' response.json && cat response.json"
  }
}

output "schedule_info" {
  description = "스케줄 정보 (한국 시간 기준)"
  value = var.enable_schedule ? {
    enabled = var.schedule_enabled
    start_utc = var.start_schedule
    stop_utc = var.stop_schedule
    note = "UTC 시간입니다. 한국 시간은 +9시간"
    example_kst = "cron(0 10 * * ? *) = 한국시간 19:00 (저녁 7시)"
  } : null
}

output "cost_savings_estimate" {
  description = "예상 비용 절감"
  value = {
    without_automation = "24시간 × 30일 = 720시간/월"
    with_automation_4h = "4시간 × 30일 = 120시간/월"
    savings_percentage = "83% 절감"
    monthly_cost_480p = {
      without = "$504 (720h × $0.70)"
      with = "$84 (120h × $0.70)"
      saved = "$420"
    }
    monthly_cost_720p = {
      without = "$1,015 (720h × $1.41)"
      with = "$169 (120h × $1.41)"
      saved = "$846"
    }
  }
}
