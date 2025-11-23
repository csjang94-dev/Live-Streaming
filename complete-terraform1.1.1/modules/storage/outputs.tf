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
