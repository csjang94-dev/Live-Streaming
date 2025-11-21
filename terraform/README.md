# AWS 라이브 스트리밍 인프라 - Terraform

Larix Broadcaster 모바일 앱을 통한 라이브 스트리밍을 위한 완전 관리형 AWS 인프라

## 프로젝트 구조

```
terraform/
├── modules/              # 재사용 가능한 Terraform 모듈
│   ├── network/         # VPC, Security Groups
│   ├── iam/            # IAM Roles & Policies
│   ├── storage/        # S3 Buckets
│   ├── mediapackage/   # MediaPackage Channel & Endpoints
│   ├── medialive/      # MediaLive Input & Channel
│   ├── cloudfront/     # CloudFront Distribution
│   ├── monitoring/     # CloudWatch Dashboard & Alarms
│   └── automation/     # Lambda Functions & EventBridge
├── environments/        # 환경별 설정
│   ├── dev/           # 개발 환경
│   ├── staging/       # 스테이징 환경
│   └── prod/          # 프로덕션 환경
└── README.md
```

## 순차적 구축 가이드 (옵션 A)

### Phase 1: 기본 인프라 (30분)

비용: 무료
구성: VPC, Security Groups, IAM Roles

```bash
cd environments/dev
terraform init
terraform plan -target=module.network -target=module.iam
terraform apply -target=module.network -target=module.iam
```

**확인 사항:**
- IAM Role이 생성되었는지
- Security Group이 RTMP 포트를 허용하는지

### Phase 2: 스토리지 (15분)

비용: ~$0.023/GB/월
구성: S3 Bucket, Lifecycle Policy

```bash
terraform plan -target=module.storage
terraform apply -target=module.storage
```

**확인 사항:**
- S3 버킷이 생성되었는지
- Lifecycle 정책이 적용되었는지

### Phase 3: MediaPackage (45분)

비용: $0.06/GB Egress (스트리밍할 때만)
구성: Channel, HLS Endpoint

```bash
terraform plan -target=module.mediapackage
terraform apply -target=module.mediapackage
```

**확인 사항:**
```bash
# MediaPackage Endpoint URL 확인
terraform output mediapackage_hls_endpoint

# 엔드포인트 응답 테스트 (404는 정상)
curl -I $(terraform output -raw mediapackage_hls_endpoint)/index.m3u8
```

**✅ Phase 1~3 완료 후 상태**
- 인프라 준비 완료
- 아직 스트리밍 불가 (MediaLive 없음)
- 비용: 거의 $0

### Phase 4: MediaLive (1시간)

비용: $2.82/시간 (HD), $0.70/시간 (SD) - **채널 시작 시에만**
구성: RTMP Input, Encoding Channel

```bash
terraform plan -target=module.medialive
terraform apply -target=module.medialive
```

**⚠️ 중요: 채널은 생성만 하고 시작하지 않으면 과금 없음**

**Larix Broadcaster 설정:**
```bash
# RTMP URL 확인
terraform output medialive_rtmp_url

# 출력 예시:
# rtmp://12.34.56.78:1935/live/stream-key-1
```

**테스트 순서:**
1. AWS Console에서 MediaLive 채널 시작
2. Larix Broadcaster에 RTMP URL 입력
3. 스트리밍 시작 (5분 테스트)
4. MediaPackage 엔드포인트 확인
5. 즉시 채널 중지

**비용: 5분 테스트 = $0.24**

### Phase 5: CloudFront (30분)

비용: $0.085/GB 전송
구성: CDN Distribution

```bash
terraform plan -target=module.cloudfront
terraform apply -target=module.cloudfront
```

**확인 사항:**
```bash
# CloudFront URL 확인
terraform output cloudfront_url

# 최종 스트리밍 URL
echo "https://$(terraform output -raw cloudfront_domain)/out/v1/$(terraform output -raw mediapackage_endpoint_id)/index.m3u8"
```

**웹 플레이어 테스트:**
- HLS.js 또는 Video.js로 재생
- VLC Player로도 테스트 가능

### Phase 6: 모니터링 (45분, 선택)

비용: $3/월 (대시보드)
구성: CloudWatch Dashboard, Alarms

```bash
terraform plan -target=module.monitoring
terraform apply -target=module.monitoring
```

### Phase 7: 자동화 (1시간, 선택)

비용: 거의 무료
구성: Lambda 시작/중지 함수, EventBridge

```bash
terraform plan -target=module.automation
terraform apply -target=module.automation
```

## 사전 준비

### 1. AWS CLI 설치 및 설정

```bash
# AWS CLI 설치 확인
aws --version

# 인증 설정
aws configure
# AWS Access Key ID: 입력
# AWS Secret Access Key: 입력
# Default region: ap-northeast-2
# Default output format: json
```

### 2. Terraform 설치

```bash
# macOS
brew install terraform

# Windows
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# 설치 확인
terraform version
```

### 3. 변수 파일 설정

`environments/dev/terraform.tfvars` 파일 수정:

```hcl
project_name = "my-live-stream"
environment  = "dev"
region      = "ap-northeast-2"

# 화질 설정 (비용 절감)
video_quality = "480p"  # "1080p", "720p", "480p"

# 태그
tags = {
  Project     = "LiveStreaming"
  Environment = "Development"
  ManagedBy   = "Terraform"
}
```

## 비용 관리

### 테스트 비용 (480p, 5분)
- MediaLive: $0.06
- MediaPackage: $0.01
- CloudFront: $0.01
- S3: $0.001
- **총합: ~$0.08**

### 일일 1시간 운영 (480p, 30일)
- MediaLive: $21/월
- MediaPackage: $3.60/월
- CloudFront: $5.10/월
- S3: $1.38/월
- **총합: ~$31/월**

### 비용 절감 팁
1. 사용하지 않을 때 채널 중지
2. 480p로 테스트 (1080p의 1/4 비용)
3. S3 7일 후 자동 삭제 설정
4. CloudFront 캐시 최적화

## 제거 방법

**전체 인프라 제거:**
```bash
cd environments/dev
terraform destroy
```

**특정 Phase만 제거:**
```bash
# MediaLive만 제거 (고비용 서비스)
terraform destroy -target=module.medialive
```

## 트러블슈팅

### 문제 1: Terraform 실행 오류

```bash
# 상태 파일 재초기화
terraform init -reconfigure

# 상태 확인
terraform show
```

### 문제 2: AWS 권한 오류

필요한 IAM 권한:
- MediaLive Full Access
- MediaPackage Full Access
- CloudFront Full Access
- S3 Full Access
- IAM Role 생성 권한

### 문제 3: 리소스 생성 실패

```bash
# 상세 로그 확인
export TF_LOG=DEBUG
terraform apply
```

## 다음 단계

1. ✅ Phase 1~3 완료 후: MediaPackage 엔드포인트 확보
2. ✅ Phase 4 완료 후: Larix로 5분 테스트
3. ✅ Phase 5 완료 후: 웹 플레이어 제작
4. ✅ Phase 6~7: 포트폴리오 고급 기능

## 포트폴리오 문서화

완성 후 다음 자료 준비:
1. 아키텍처 다이어그램
2. Terraform 코드 설명
3. 비용 분석 리포트
4. 테스트 영상 (화면 녹화)
5. 트러블슈팅 경험

## 참고 자료

- AWS MediaLive 문서: https://docs.aws.amazon.com/medialive/
- AWS MediaPackage 문서: https://docs.aws.amazon.com/mediapackage/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
