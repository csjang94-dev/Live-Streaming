variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "archive_retention_days" {
  description = "Archive 파일 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진 목록"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
