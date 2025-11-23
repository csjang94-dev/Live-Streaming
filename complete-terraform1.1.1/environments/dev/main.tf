terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# ==================== Phase 1: Storage ====================
module "storage" {
  source = "../../modules/storage"

  project_name           = var.project_name
  environment            = var.environment
  archive_retention_days = var.archive_retention_days
  cors_allowed_origins   = ["*"]
  
  tags = var.tags
}

# ==================== Phase 2: Network ====================
module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  region             = var.region
  create_vpc         = false
  allowed_rtmp_cidrs = var.allowed_rtmp_cidrs
  
  tags = var.tags
}

# ==================== Phase 3: IAM ====================
module "iam" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  archive_bucket_arn = module.storage.archive_bucket_arn
  hls_bucket_arn      = module.storage.hls_bucket_arn

  create_lambda_role      = true
  create_eventbridge_role = true
  
  tags = var.tags

  depends_on = [module.storage]
}

# ==================== Phase 4: MediaLive ====================
module "medialive" {
  source = "../../modules/medialive"

  project_name = var.project_name
  environment  = var.environment
  
  # IAM
  iam_role_arn = module.iam.medialive_role_arn
  
  # Network
  security_group_id = module.network.security_group_id
  
  # S3 HLS Output
  hls_bucket_name = module.storage.hls_bucket_name
  
  # S3 Archive
  enable_archive      = var.enable_archive
  archive_bucket_name = module.storage.archive_bucket_name
  
  # 채널 설정
  video_quality = var.video_quality
  channel_class = var.channel_class
  
  tags = var.tags

  depends_on = [module.iam, module.storage]
}

# ==================== Phase 5: Automation ====================
module "automation" {
  source = "../../modules/automation"

  project_name = var.project_name
  environment  = var.environment
  
  # IAM Role
  lambda_role_arn = module.iam.lambda_role_arn
  
  # MediaLive 채널
  medialive_channel_id = module.medialive.channel_id
  
  # 스케줄 설정
  enable_schedule              = var.enable_automation_schedule
  schedule_enabled             = var.schedule_enabled
  start_schedule               = var.start_schedule
  stop_schedule                = var.stop_schedule
  enable_error_notifications   = var.enable_automation_error_notifications
  error_notification_email     = var.automation_error_email
  log_retention_days           = var.automation_log_retention_days
  
  tags = var.tags

  depends_on = [module.medialive, module.iam]
}
