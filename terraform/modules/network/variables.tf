variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
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

variable "create_vpc" {
  description = "새 VPC 생성 여부 (false면 기본 VPC 사용)"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록 (create_vpc = true인 경우)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "allowed_rtmp_cidrs" {
  description = "RTMP/RTMPS 접속을 허용할 IP 대역"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_vpc_endpoints" {
  description = "VPC Endpoints 생성 여부 (비용 발생)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}
