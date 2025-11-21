variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "archive_bucket_arn" {
  description = "S3 Archive Bucket ARN (Phase 2에서 생성)"
  type        = string
}

variable "create_lambda_role" {
  description = "Lambda Role 생성 여부 (Phase 7에서 사용)"
  type        = bool
  default     = true
}

variable "create_eventbridge_role" {
  description = "EventBridge Role 생성 여부 (Phase 7에서 사용)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
