variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "mediapackage_domain" {
  description = "MediaPackage Origin 도메인 (https:// 제외)"
  type        = string
}

variable "mediapackage_path" {
  description = "MediaPackage Origin 경로"
  type        = string
}

variable "price_class" {
  description = "CloudFront Price Class (비용/성능 균형)"
  type        = string
  default     = "PriceClass_200"

  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200",
      "PriceClass_100"
    ], var.price_class)
    error_message = "price_class는 PriceClass_All, PriceClass_200, PriceClass_100 중 하나여야 합니다."
  }
}

variable "enable_custom_cache_policy" {
  description = "커스텀 캐시 정책 사용 여부"
  type        = bool
  default     = false
}

variable "enable_cors" {
  description = "CORS 헤더 활성화 여부"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "CORS 허용 Origins"
  type        = list(string)
  default     = ["*"]
}

variable "custom_domain" {
  description = "커스텀 도메인 (예: stream.example.com), 빈 문자열이면 CloudFront 기본 도메인 사용"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN (커스텀 도메인 사용 시 필수, us-east-1 리전)"
  type        = string
  default     = ""
}

variable "geo_restriction_type" {
  description = "지역 제한 타입 (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type은 none, whitelist, blacklist 중 하나여야 합니다."
  }
}

variable "geo_restriction_locations" {
  description = "지역 제한 국가 코드 목록 (ISO 3166-1-alpha-2)"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "CloudFront Access Logging 활성화 여부"
  type        = bool
  default     = false
}

variable "logging_bucket_domain_name" {
  description = "로그 저장용 S3 Bucket Domain Name"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "로그 파일 Prefix"
  type        = string
  default     = "cloudfront-logs/"
}

variable "enable_alarms" {
  description = "CloudWatch Alarms 활성화 여부"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "알람 전송용 SNS Topic ARN"
  type        = string
  default     = ""
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
