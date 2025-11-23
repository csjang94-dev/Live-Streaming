variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "medialive_channel_id" {
  description = "MediaLive Channel ID"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "CloudWatch Alarms 활성화 여부"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "알람 수신 이메일 주소"
  type        = string
  default     = ""
}

variable "enable_budget_alert" {
  description = "비용 예산 알람 활성화 여부"
  type        = bool
  default     = false
}

variable "monthly_budget_limit" {
  description = "월간 예산 한도 (USD)"
  type        = number
  default     = 100
}

variable "budget_alert_emails" {
  description = "비용 알람 수신 이메일 목록"
  type        = list(string)
  default     = []
}

variable "enable_logs" {
  description = "CloudWatch Logs 활성화 여부"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "로그 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
