variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "archive_bucket_arn" {
  description = "HLS S3 bucket ARN"
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

# modules/iam/variables.tf (이 변수가 존재해야 함)
variable "hls_bucket_arn" {
  description = "The ARN of the HLS S3 bucket."
  type        = string
}
