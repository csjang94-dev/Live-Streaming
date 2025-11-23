output "dashboard_name" {
  description = "CloudWatch Dashboard 이름"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "알람용 SNS Topic ARN"
  value       = aws_sns_topic.alarms.arn
}

output "sns_topic_name" {
  description = "알람용 SNS Topic 이름"
  value       = aws_sns_topic.alarms.name
}

output "alarm_names" {
  description = "생성된 알람 목록"
  value = var.enable_alarms ? concat(
    aws_cloudwatch_metric_alarm.medialive_dropped_frames[*].alarm_name,
    aws_cloudwatch_metric_alarm.medialive_active_alerts[*].alarm_name,
    aws_cloudwatch_metric_alarm.medialive_low_framerate[*].alarm_name,
    aws_cloudwatch_metric_alarm.cloudfront_4xx_error_rate[*].alarm_name,
    aws_cloudwatch_metric_alarm.cloudfront_5xx_error_rate[*].alarm_name,
    aws_cloudwatch_metric_alarm.cloudfront_cache_hit_rate[*].alarm_name
  ) : []
}

output "budget_name" {
  description = "생성된 Budget 이름"
  value       = var.enable_budget_alert ? aws_budgets_budget.monthly_cost[0].name : null
}

output "monitoring_commands" {
  description = "모니터링 관련 유용한 명령어"
  value = {
    view_dashboard = "aws cloudwatch get-dashboard --dashboard-name ${aws_cloudwatch_dashboard.main.dashboard_name}"
    list_alarms    = "aws cloudwatch describe-alarms --alarm-name-prefix ${var.project_name}-${var.environment}"
    test_alarm     = "aws sns publish --topic-arn ${aws_sns_topic.alarms.arn} --message 'Test alarm notification'"
  }
}
