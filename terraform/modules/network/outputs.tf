output "vpc_id" {
  description = "VPC ID"
  value       = var.create_vpc ? aws_vpc.main[0].id : data.aws_vpc.default[0].id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : data.aws_vpc.default[0].cidr_block
}

output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = var.create_vpc ? aws_subnet.public[*].id : data.aws_subnets.default[0].ids
}

output "security_group_id" {
  description = "MediaLive Input Security Group ID"
  value       = aws_security_group.medialive_input.id
}

output "security_group_name" {
  description = "MediaLive Input Security Group 이름"
  value       = aws_security_group.medialive_input.name
}
