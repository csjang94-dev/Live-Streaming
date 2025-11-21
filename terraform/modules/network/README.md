# Network 모듈

MediaLive RTMP 입력을 위한 네트워크 및 보안 그룹 구성

## 기능

- VPC 생성 (선택사항)
- Public Subnets
- Internet Gateway
- RTMP/RTMPS용 Security Group
- VPC Endpoints (선택사항)

## 사용법

```hcl
module "network" {
  source = "../../modules/network"

  project_name = "my-live-stream"
  environment  = "dev"
  region       = "ap-northeast-2"
  
  # VPC를 생성하지 않고 기본 VPC 사용
  create_vpc = false
  
  # RTMP 접속 허용 IP (보안 강화를 위해 특정 IP로 제한 권장)
  allowed_rtmp_cidrs = ["0.0.0.0/0"]
  
  tags = {
    Project = "LiveStreaming"
  }
}
```

## 입력 변수

| 변수 | 설명 | 타입 | 기본값 | 필수 |
|------|------|------|--------|------|
| project_name | 프로젝트 이름 | string | - | ✅ |
| environment | 환경 | string | - | ✅ |
| region | AWS 리전 | string | - | ✅ |
| create_vpc | VPC 생성 여부 | bool | false | ❌ |
| vpc_cidr | VPC CIDR | string | 10.0.0.0/16 | ❌ |
| allowed_rtmp_cidrs | RTMP 허용 CIDR | list(string) | ["0.0.0.0/0"] | ❌ |

## 출력 값

| 출력 | 설명 |
|------|------|
| vpc_id | VPC ID |
| public_subnet_ids | Public Subnet ID 목록 |
| security_group_id | Security Group ID |

## 보안 권장사항

### 프로덕션 환경

RTMP 접속 IP를 특정 범위로 제한:

```hcl
allowed_rtmp_cidrs = [
  "203.0.113.0/24",  # 사무실 IP
  "198.51.100.0/24"  # VPN IP
]
```

### 모바일 네트워크 IP 범위

한국 주요 통신사 IP 대역 (예시):
```hcl
allowed_rtmp_cidrs = [
  "10.0.0.0/8",      # 내부 네트워크
  "0.0.0.0/0"        # 모든 IP (테스트용만)
]
```

## 비용

- VPC: 무료
- Security Group: 무료
- VPC Endpoint: ~$7.30/월 (선택사항)

## 주의사항

1. **기본 VPC 사용 권장** (create_vpc = false)
   - 설정이 간단함
   - 추가 비용 없음
   - MediaLive는 VPC 없이도 작동

2. **Security Group 설정**
   - 프로덕션에서는 반드시 특정 IP로 제한
   - 0.0.0.0/0은 테스트용으로만 사용
