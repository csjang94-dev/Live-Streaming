variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "iam_role_arn" {
  description = "MediaLive IAM Role ARN"
  type        = string
}

variable "security_group_id" {
  description = "RTMP Input Security Group ID"
  type        = string
}

variable "video_quality" {
  description = "비디오 화질 (1080p, 720p, 480p)"
  type        = string
  default     = "720p"

  validation {
    condition     = contains(["1080p", "720p", "480p"], var.video_quality)
    error_message = "video_quality는 1080p, 720p, 480p 중 하나여야 합니다."
  }
}

variable "channel_class" {
  description = "채널 클래스 (SINGLE_PIPELINE: 저렴, STANDARD: 이중화)"
  type        = string
  default     = "SINGLE_PIPELINE"

  validation {
    condition     = contains(["SINGLE_PIPELINE", "STANDARD"], var.channel_class)
    error_message = "channel_class는 SINGLE_PIPELINE 또는 STANDARD여야 합니다."
  }
}

# S3 HLS Output
variable "hls_bucket_name" {
  description = "HLS 출력용 S3 Bucket 이름"
  type        = string
}

variable "enable_archive" {
  description = "S3 Archive 활성화 여부"
  type        = bool
  default     = true
}

variable "archive_bucket_name" {
  description = "S3 Archive Bucket 이름"
  type        = string
  default     = ""
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
