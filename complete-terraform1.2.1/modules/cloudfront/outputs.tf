output "distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "CloudFront Distribution 도메인"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "hls_playback_url" {
  description = "HLS 재생 URL (전체 경로)"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}${var.mediapackage_path}/index.m3u8"
}

output "distribution_status" {
  description = "CloudFront Distribution 상태"
  value       = aws_cloudfront_distribution.main.status
}

output "distribution_etag" {
  description = "CloudFront Distribution ETag"
  value       = aws_cloudfront_distribution.main.etag
}

output "cdn_identifier" {
  description = "MediaPackage CDN Identifier"
  value       = random_string.cdn_identifier.result
  sensitive   = true
}

# 커스텀 도메인 (설정된 경우)
output "custom_domain" {
  description = "설정된 커스텀 도메인"
  value       = var.custom_domain != "" ? var.custom_domain : null
}

output "custom_domain_playback_url" {
  description = "커스텀 도메인 재생 URL"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}${var.mediapackage_path}/index.m3u8" : null
}

# 테스트용 명령어
output "test_commands" {
  description = "CloudFront 테스트 명령어"
  value = {
    curl_test = "curl -I https://${aws_cloudfront_distribution.main.domain_name}${var.mediapackage_path}/index.m3u8"
    vlc_test  = "vlc https://${aws_cloudfront_distribution.main.domain_name}${var.mediapackage_path}/index.m3u8"
    browser_url = "https://${aws_cloudfront_distribution.main.domain_name}${var.mediapackage_path}/index.m3u8"
  }
}

# 캐시 통계
output "cache_policy_ids" {
  description = "생성된 Cache Policy ID들"
  value = {
    manifest = aws_cloudfront_cache_policy.manifest.id
    segments = aws_cloudfront_cache_policy.segments.id
    custom   = var.enable_custom_cache_policy ? aws_cloudfront_cache_policy.hls[0].id : null
  }
}

# 비용 관련 정보
output "cost_info" {
  description = "CloudFront 비용 관련 정보"
  value = {
    price_class = var.price_class
    price_class_description = var.price_class == "PriceClass_All" ? "전 세계 모든 엣지" : (
      var.price_class == "PriceClass_200" ? "미국, 유럽, 아시아, 중동, 아프리카" : "미국, 유럽, 캐나다"
    )
    estimated_cost_per_gb = var.price_class == "PriceClass_All" ? 0.085 : (
      var.price_class == "PriceClass_200" ? 0.085 : 0.085
    )
    note = "첫 10TB까지 $0.085/GB, 이후 단계별 할인"
  }
}
