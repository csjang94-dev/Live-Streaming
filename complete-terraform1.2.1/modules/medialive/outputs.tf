output "input_id" {
  description = "MediaLive Input ID"
  value       = aws_medialive_input.rtmp.id
}

output "channel_id" {
  description = "MediaLive Channel ID"
  value       = aws_medialive_channel.main.id
}

output "channel_arn" {
  description = "MediaLive Channel ARN"
  value       = aws_medialive_channel.main.arn
}

output "rtmp_destinations" {
  description = "RTMP Push Destinations (IP 주소 확인용)"
  value       = aws_medialive_input.rtmp.destinations
}

output "rtmp_url" {
  description = "RTMP URL 안내 (실제 IP는 destinations 출력 확인)"
  value       = "rtmp://[IP_FROM_DESTINATIONS]:1935/stream-key-1"
}

output "video_quality" {
  description = "설정된 비디오 화질"
  value       = var.video_quality
}

output "channel_class" {
  description = "채널 클래스 (비용 관련)"
  value       = var.channel_class
}

# 비용 예상
output "estimated_cost" {
  description = "예상 시간당 비용 (USD)"
  value = {
    per_hour = var.channel_class == "SINGLE_PIPELINE" ? (
      var.video_quality == "1080p" ? 2.82 :
      var.video_quality == "720p" ? 1.41 : 0.70
    ) : (
      var.video_quality == "1080p" ? 5.64 :
      var.video_quality == "720p" ? 2.82 : 1.40
    )
    per_day_4h = var.channel_class == "SINGLE_PIPELINE" ? (
      var.video_quality == "1080p" ? 11.28 :
      var.video_quality == "720p" ? 5.64 : 2.80
    ) : (
      var.video_quality == "1080p" ? 22.56 :
      var.video_quality == "720p" ? 11.28 : 5.60
    )
    channel_class = var.channel_class
    video_quality = var.video_quality
    note = "채널이 Running 상태일 때만 과금됩니다"
  }
}
