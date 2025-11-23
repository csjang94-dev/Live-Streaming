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
  default     = "ap-northeast-2"
}

# Network
variable "allowed_rtmp_cidrs" {
  description = "RTMP 접속을 허용할 IP 대역"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Storage
variable "archive_retention_days" {
  description = "S3 Archive 보관 기간 (일)"
  type        = number
  default     = 7
}

# MediaLive
variable "video_quality" {
  description = "비디오 화질 (480p, 720p, 1080p)"
  type        = string
  default     = "480p"
}

variable "channel_class" {
  description = "MediaLive 채널 클래스 (SINGLE_PIPELINE, STANDARD)"
  type        = string
  default     = "SINGLE_PIPELINE"
}

variable "enable_archive" {
  description = "S3 Archive 활성화 여부"
  type        = bool
  default     = true
}

# Automation
variable "enable_automation_schedule" {
  description = "자동 스케줄 활성화 여부"
  type        = bool
  default     = false
}

variable "schedule_enabled" {
  description = "EventBridge 스케줄 활성화"
  type        = bool
  default     = true
}

variable "start_schedule" {
  description = "채널 시작 스케줄 (cron)"
  type        = string
  default     = "cron(0 10 * * ? *)"
}

variable "stop_schedule" {
  description = "채널 중지 스케줄 (cron)"
  type        = string
  default     = "cron(0 14 * * ? *)"
}

variable "enable_automation_error_notifications" {
  description = "Lambda 에러 알림 활성화"
  type        = bool
  default     = false
}

variable "automation_error_email" {
  description = "Lambda 에러 알림 이메일"
  type        = string
  default     = ""
}

variable "automation_log_retention_days" {
  description = "Lambda 로그 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "모든 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
