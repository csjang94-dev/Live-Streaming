terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 기본 VPC 조회 (create_vpc = false인 경우)
data "aws_vpc" "default" {
  count   = var.create_vpc ? 0 : 1
  default = true
}

# 기본 VPC의 Subnets 조회
data "aws_subnets" "default" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# 새 VPC 생성 (create_vpc = true인 경우)
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# Internet Gateway (새 VPC용)
resource "aws_internet_gateway" "main" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

# Public Subnets (새 VPC용)
resource "aws_subnet" "public" {
  count = var.create_vpc ? length(var.availability_zones) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    }
  )
}

# Route Table (새 VPC용)
resource "aws_route_table" "public" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
    }
  )
}

# Route Table Association (새 VPC용)
resource "aws_route_table_association" "public" {
  count = var.create_vpc ? length(aws_subnet.public) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Security Group for MediaLive RTMP Input
resource "aws_security_group" "medialive_input" {
  name        = "${var.project_name}-${var.environment}-medialive-input"
  description = "Security group for MediaLive RTMP input"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : data.aws_vpc.default[0].id

  # RTMP (TCP 1935)
  ingress {
    description = "RTMP"
    from_port   = 1935
    to_port     = 1935
    protocol    = "tcp"
    cidr_blocks = var.allowed_rtmp_cidrs
  }

  # RTMPS (TCP 443)
  ingress {
    description = "RTMPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_rtmp_cidrs
  }

  # Outbound - 모든 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-medialive-input-sg"
    }
  )
}

# VPC Endpoints (선택사항, 비용 발생)
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = var.create_vpc ? aws_vpc.main[0].id : data.aws_vpc.default[0].id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.create_vpc ? [aws_route_table.public[0].id] : []

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-s3-endpoint"
    }
  )
}
