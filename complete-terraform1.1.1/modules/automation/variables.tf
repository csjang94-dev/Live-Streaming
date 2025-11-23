variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  type        = string
}

variable "medialive_channel_id" {
  description = "MediaLive Channel ID"
  type        = string
}

variable "enable_schedule" {
  description = "자동 스케줄 활성화 여부"
  type        = bool
  default     = false
}

variable "schedule_enabled" {
  description = "스케줄 규칙 활성화 여부 (일시적 비활성화 가능)"
  type        = bool
  default     = true
}

variable "start_schedule" {
  description = "시작 스케줄 (cron 또는 rate 표현식)"
  type        = string
  default     = "cron(0 19 * * ? *)"  # 매일 오후 7시 (UTC 기준이므로 한국시간 새벽 4시)
}

variable "stop_schedule" {
  description = "중지 스케줄 (cron 또는 rate 표현식)"
  type        = string
  default     = "cron(0 23 * * ? *)"  # 매일 오후 11시 (UTC 기준이므로 한국시간 오전 8시)
}

variable "enable_error_notifications" {
  description = "Lambda 에러 알림 활성화 여부"
  type        = bool
  default     = false
}

variable "error_notification_email" {
  description = "Lambda 에러 알림 이메일"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Lambda 로그 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
