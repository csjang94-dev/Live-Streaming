# ==============================================
# 기본 설정
# ==============================================
project_name = "live-streaming"
environment  = "dev"
region       = "ap-northeast-2"

# ==============================================
# Network
# ==============================================
allowed_rtmp_cidrs = ["0.0.0.0/0"]  # 모든 IP 허용 (테스트용)

# ==============================================
# Storage
# ==============================================
archive_retention_days = 7  # S3 Archive 7일 후 자동 삭제

# ==============================================
# MediaLive
# ==============================================
video_quality  = "480p"            # "480p", "720p", "1080p"
channel_class  = "SINGLE_PIPELINE" # "SINGLE_PIPELINE" (저렴), "STANDARD" (이중화)
enable_archive = true              # S3 Archive 활성화

# ==============================================
# Automation
# ==============================================
enable_automation_schedule        = false # 자동 스케줄 비활성화 (수동 제어)
schedule_enabled                  = true
start_schedule                    = "cron(0 10 * * ? *)" # UTC 10:00 = 한국 19:00
stop_schedule                     = "cron(0 14 * * ? *)" # UTC 14:00 = 한국 23:00
enable_automation_error_notifications = false
automation_error_email            = ""
automation_log_retention_days     = 7

# ==============================================
# 리소스 태그
# ==============================================
tags = {
  Project     = "LiveStreaming"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "GJJANG"
  Purpose     = "Portfolio"
}
