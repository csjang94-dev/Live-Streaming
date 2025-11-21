terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State 파일 로컬 저장 (실제 운영에서는 S3 backend 사용 권장)
  backend "local" {
    path = "terraform.tfstate"
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# Phase 2: Storage 모듈 (IAM보다 먼저 생성해야 함)
module "storage" {
  source = "../../modules/storage"

  project_name            = var.project_name
  environment             = var.environment
  archive_retention_days  = var.archive_retention_days
  cors_allowed_origins    = ["*"]
  
  tags = var.tags
}

# Phase 1: Network 모듈
module "network" {
  source = "../../modules/network"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  create_vpc          = false  # 기본 VPC 사용
  allowed_rtmp_cidrs  = var.allowed_rtmp_cidrs
  
  tags = var.tags
}

# Phase 1: IAM 모듈
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  
  # Storage 모듈이 생성된 후 업데이트
  archive_bucket_arn = module.storage.archive_bucket_arn
  
  # Phase 7에서 Lambda 사용
  create_lambda_role      = true
  create_eventbridge_role = false
  
  tags = var.tags

  # IAM은 Storage에 의존
  depends_on = [module.storage]
}
