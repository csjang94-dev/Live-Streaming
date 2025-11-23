# HLS Bucket Outputs
output "hls_bucket_id" {
  description = "HLS S3 Bucket ID"
  value       = aws_s3_bucket.hls.id
}

output "hls_bucket_arn" {
  description = "HLS S3 Bucket ARN"
  value       = aws_s3_bucket.hls.arn
}

output "hls_bucket_name" {
  description = "HLS S3 Bucket 이름"
  value       = aws_s3_bucket.hls.bucket
}

output "hls_bucket_regional_domain" {
  description = "HLS S3 Bucket Regional Domain"
  value       = aws_s3_bucket.hls.bucket_regional_domain_name
}

# Archive Bucket Outputs
output "archive_bucket_id" {
  description = "Archive S3 Bucket ID"
  value       = aws_s3_bucket.archive.id
}

output "archive_bucket_arn" {
  description = "Archive S3 Bucket ARN"
  value       = aws_s3_bucket.archive.arn
}

output "archive_bucket_name" {
  description = "Archive S3 Bucket 이름"
  value       = aws_s3_bucket.archive.bucket
}

output "archive_bucket_region" {
  description = "Archive S3 Bucket 리전"
  value       = aws_s3_bucket.archive.region
}

# Player Hosting Outputs
output "player_bucket_id" {
  description = "Player hosting bucket ID"
  value       = aws_s3_bucket.player.id
}

output "player_bucket_arn" {
  description = "Player hosting bucket ARN"
  value       = aws_s3_bucket.player.arn
}

output "player_bucket_domain" {
  description = "Player bucket domain name"
  value       = aws_s3_bucket.player.bucket_regional_domain_name
}

output "player_website_endpoint" {
  description = "Player website endpoint"
  value       = aws_s3_bucket_website_configuration.player.website_endpoint
}

# HLS Bucket Domain 추가
output "hls_bucket_domain" {
  description = "HLS bucket regional domain name"
  value       = aws_s3_bucket.hls.bucket_regional_domain_name
}