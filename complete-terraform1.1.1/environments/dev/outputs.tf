# ==================== Storage ====================
output "hls_bucket_name" {
  description = "HLS S3 Bucket 이름"
  value       = module.storage.hls_bucket_name
}

output "archive_bucket_name" {
  description = "Archive S3 Bucket 이름"
  value       = module.storage.archive_bucket_name
}

# ==================== MediaLive ====================
output "medialive_channel_id" {
  description = "MediaLive Channel ID"
  value       = module.medialive.channel_id
}

output "medialive_rtmp_url" {
  description = "RTMP 입력 URL (Larix Broadcaster에 입력)"
  value       = module.medialive.rtmp_url
}

output "medialive_rtmp_destinations" {
  description = "RTMP Destinations (실제 IP 주소 확인)"
  value       = module.medialive.rtmp_destinations
}

output "medialive_channel_state" {
  description = "MediaLive 채널 상태"
  value       = "배포 직후: IDLE (시작 필요)"
}

# ==================== Automation ====================
output "automation_lambda_function_name" {
  description = "채널 제어 Lambda 함수 이름"
  value       = module.automation.lambda_function_name
}

output "automation_lambda_arn" {
  description = "채널 제어 Lambda ARN"
  value       = module.automation.lambda_function_arn
}

# ==================== HLS 재생 ====================
output "hls_s3_url" {
  description = "HLS S3 URL (CloudFront 없이 직접 재생 - 테스트용)"
  value       = "https://${module.storage.hls_bucket_regional_domain}/live/index.m3u8"
}

# ==================== 요약 ====================
output "deployment_summary" {
  description = "배포 요약"
  value = <<-EOT
  
  ╔═══════════════════════════════════════════════════════════╗
  ║        AWS 라이브 스트리밍 배포 완료! ✅                    ║
  ╚═══════════════════════════════════════════════════════════╝
  
  📦 생성된 리소스:
  ─────────────────────────────────────────────────────────────
  ✅ S3 Buckets (HLS, Archive)
  ✅ MediaLive Channel (RTMP Input)
  ✅ Lambda Function (자동화)
  ✅ IAM Roles & Security Groups
  
  🎬 스트리밍 시작하기:
  ─────────────────────────────────────────────────────────────
  
  1️⃣  MediaLive 채널 시작:
      aws lambda invoke \\
        --function-name ${module.automation.lambda_function_name} \\
        --payload '{"action": "start"}' response.json
      
      (30초 대기...)
  
  2️⃣  Larix Broadcaster 설정:
      먼저 RTMP IP 확인:
      terraform output medialive_rtmp_destinations
      
      Larix 설정:
      RTMP URL: rtmp://[위_IP]:1935/stream-key-1
      Stream Key: stream-key-1
  
  3️⃣  재생 확인:
      S3 Direct: https://${module.storage.hls_bucket_regional_domain}/live/index.m3u8
      
      VLC로 재생:
      vlc "https://${module.storage.hls_bucket_regional_domain}/live/index.m3u8"
  
  4️⃣  스트리밍 중지:
      aws lambda invoke \\
        --function-name ${module.automation.lambda_function_name} \\
        --payload '{"action": "stop"}' response.json
  
  💰 비용:
  ─────────────────────────────────────────────────────────────
  현재 (채널 중지): ~$0/월
  480p 스트리밍 (1시간): ~$0.70
  
  📚 다음 단계:
  ─────────────────────────────────────────────────────────────
  - CloudFront CDN 추가 (선택사항)
  - 모니터링 Dashboard 추가 (선택사항)
  - 웹 플레이어 제작
  
  🎉 성공!
  
  EOT
}

# ==================== 개별 명령어 ====================
output "start_channel_command" {
  description = "채널 시작 명령어"
  value       = "aws lambda invoke --function-name ${module.automation.lambda_function_name} --payload '{\"action\": \"start\"}' response.json"
}

output "stop_channel_command" {
  description = "채널 중지 명령어"
  value       = "aws lambda invoke --function-name ${module.automation.lambda_function_name} --payload '{\"action\": \"stop\"}' response.json"
}

output "check_status_command" {
  description = "채널 상태 확인 명령어"
  value       = "aws medialive describe-channel --channel-id ${module.medialive.channel_id} --query 'State'"
}
