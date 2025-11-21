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
