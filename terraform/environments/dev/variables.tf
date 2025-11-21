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

variable "allowed_rtmp_cidrs" {
  description = "RTMP 접속을 허용할 IP 대역"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "archive_retention_days" {
  description = "S3 Archive 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "모든 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
