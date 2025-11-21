output "medialive_role_arn" {
  description = "MediaLive IAM Role ARN"
  value       = aws_iam_role.medialive.arn
}

output "medialive_role_name" {
  description = "MediaLive IAM Role 이름"
  value       = aws_iam_role.medialive.name
}

output "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  value       = var.create_lambda_role ? aws_iam_role.lambda[0].arn : null
}

output "lambda_role_name" {
  description = "Lambda IAM Role 이름"
  value       = var.create_lambda_role ? aws_iam_role.lambda[0].name : null
}

output "eventbridge_role_arn" {
  description = "EventBridge IAM Role ARN"
  value       = var.create_eventbridge_role ? aws_iam_role.eventbridge[0].arn : null
}

output "eventbridge_role_name" {
  description = "EventBridge IAM Role 이름"
  value       = var.create_eventbridge_role ? aws_iam_role.eventbridge[0].name : null
}
