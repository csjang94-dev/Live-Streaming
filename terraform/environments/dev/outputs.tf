# Network 출력
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "security_group_id" {
  description = "MediaLive Input Security Group ID"
  value       = module.network.security_group_id
}

output "subnet_ids" {
  description = "Subnet ID 목록"
  value       = module.network.public_subnet_ids
}

# IAM 출력
output "medialive_role_arn" {
  description = "MediaLive IAM Role ARN"
  value       = module.iam.medialive_role_arn
}

output "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  value       = module.iam.lambda_role_arn
}

# Storage 출력
output "archive_bucket_name" {
  description = "S3 Archive Bucket 이름"
  value       = module.storage.archive_bucket_name
}

output "archive_bucket_arn" {
  description = "S3 Archive Bucket ARN"
  value       = module.storage.archive_bucket_arn
}

# Phase 1 완료 메시지
output "phase1_completion" {
  description = "Phase 1 완료 상태"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════╗
  ║              Phase 1 배포 완료! ✅                          ║
  ╚════════════════════════════════════════════════════════════╝
  
  생성된 리소스:
  - VPC ID: ${module.network.vpc_id}
  - Security Group: ${module.network.security_group_id}
  - S3 Bucket: ${module.storage.archive_bucket_name}
  - MediaLive Role: ${module.iam.medialive_role_arn}
  - Lambda Role: ${module.iam.lambda_role_arn}
  
  다음 단계:
  1. AWS Console에서 리소스 확인
  2. Phase 2 가이드 확인 (PHASE_1-3_GUIDE.md)
  3. 준비되면 Phase 3 (MediaPackage) 진행
  
  비용: 거의 $0 (S3만 저장된 데이터만큼 과금)
  
  EOT
}
