# 기본 설정
project_name = "live-streaming"
environment  = "dev"
region       = "ap-northeast-2"

# 네트워크 설정
# 보안을 위해 특정 IP만 허용하는 것을 권장합니다
# 예: ["123.456.789.0/24", "98.765.432.1/32"]
allowed_rtmp_cidrs = ["0.0.0.0/0"]  # 모든 IP 허용 (테스트용)

# 스토리지 설정
archive_retention_days = 7  # 7일 후 자동 삭제

# 리소스 태그
tags = {
  Project     = "LiveStreaming"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "GJJANG"
}
