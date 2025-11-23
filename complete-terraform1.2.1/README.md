# 🎥 AWS 라이브 스트리밍 시스템

모바일 앱에서 전 세계로 HTTPS 라이브 스트리밍 (CloudFront CDN)

---

## 📖 목차

1. [빠른 시작](#-빠른-시작)
2. [아키텍처](#-아키텍처)
3. [사용 방법](#-사용-방법)
4. [비용 가이드](#-비용-가이드)
5. [커스터마이징](#-커스터마이징)
6. [문제 해결](#-문제-해결)
7. [포트폴리오](#-포트폴리오-하이라이트)

---

## ⚡ 빠른 시작

```bash
cd complete-terraform/environments/dev
terraform init
terraform apply  # yes 입력
```

**3분이면 완료!**

**포함된 모든 것:**
- 📱 모바일 RTMP 스트리밍 (Larix/CameraFi)
- 🌍 CloudFront CDN (HTTPS)
- 📊 자동 화질 조정 (ABR)
- 🤖 자동 시작/중지 (Lambda)
- 💰 비용 최적화

**📚 다른 문서:**
- **[QUICK_START.md](QUICK_START.md)** - 5분 시작 가이드
- **[CLOUDFRONT_GUIDE.md](CLOUDFRONT_GUIDE.md)** - CloudFront 상세

---

## 🏗️ 아키텍처

### 전체 구조

```
┌─────────────────────┐
│ 휴대폰(CameraFI Live)│  ← 스트리머
└──────────┬──────────┘
           │ RTMP (1935)
           ↓
┌─────────────────────┐      ┌─────────────────┐
│   AWS MediaLive     │◄─────│     Lambda      │
│   (H.264/AAC)       │      │  (시작/중지)     │
└──────────┬──────────┘      └────────┬────────┘
           │ HLS 세그먼트              │
           ↓                          │
┌─────────────────────┐      ┌────────┴────────┐
│      S3 HLS         │      │  EventBridge    │
│    (live/*.ts)      │      │  (스케줄-선택)    │
└──────────┬──────────┘      └─────────────────┘
           │ HTTPS
           ↓
┌─────────────────────┐
│   CloudFront CDN    │  ← 전세계 배포
│  (200+ 엣지)         │
└──────────┬──────────┘
           │ HTTPS
           ↓
     ┌──────────┐
     │ 웹 플레이어│  ← 시청자
     └──────────┘
```

### 데이터 흐름

```
1. Larix Broadcaster (모바일)
   ↓ RTMP (1935 포트)
   
2. MediaLive (인코딩)
   - H.264/AAC 변환
   - 480p/720p/1080p
   ↓ HLS 세그먼트 (.ts 파일)
   
3. S3 (저장)
   - live/index.m3u8
   - live/segment_00001.ts
   ↓ HTTPS
   
4. CloudFront (CDN)
   - 글로벌 캐싱
   - HTTPS 제공
   ↓ HTTPS
   
5. 웹 플레이어 (재생)
   - HLS.js 자동 재생
   - 적응형 화질 조정
```

### Phase별 구성

| Phase | 구성 요소 | 역할 |
|-------|----------|------|
| **Phase 1** | Network & IAM | Security Group (RTMP), IAM Roles |
| **Phase 2** | Storage | S3 HLS, S3 Archive |
| **Phase 3** | MediaLive | RTMP Input, HLS Encoder |
| **Phase 4** | CloudFront | CDN 배포, HTTPS |
| **Phase 5** | Automation | Lambda 시작/중지 |
| **Phase 6** | Monitoring | CloudWatch Dashboard |

### 기술 스택

```
프론트엔드:
- HLS.js (웹 플레이어)
- HTML5 Video

백엔드:
- AWS MediaLive (인코딩)
- AWS S3 (저장)
- AWS CloudFront (CDN)
- AWS Lambda (자동화)

인프라:
- Terraform (IaC)
- AWS CLI

프로토콜:
- RTMP (입력)
- HLS (출력)
- H.264 (비디오)
- AAC (오디오)
```

---

## 🚀 사용 방법

### 1. 채널 시작
```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RhcnQifQ== \
  response.json

# ⏳ 2분 대기 (채널 시작 중)
```

### 2. 스트리밍 설정

**RTMP URL 확인:**
```bash
terraform output medialive_rtmp_url
```

**CameraFi Live / Larix 설정:**
```
Server: rtmp://xx.xx.xx.xx:1935/live
Stream Key: stream-key-1

비디오: H.264
오디오: AAC
비트레이트: 2500 Kbps (720p 권장)
```

**GO LIVE 버튼!** 🔴

### 3. 시청

**플레이어 URL:**
```bash
terraform output player_cloudfront_url
# 출력: https://d1234567890.cloudfront.net
```

**브라우저에서 열기** → 자동 재생! 🎉

### 4. 모니터링

**실시간 상태:**
```bash
# S3 파일 확인
aws s3 ls s3://$(terraform output -raw hls_bucket_name)/live/

# 채널 상태
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State
```

### 5. 중지 (중요!)

```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RvcCJ9 \
  response.json
```

**⚠️ 반드시 중지하세요! 비용 발생합니다!**

---

## 💰 비용 가이드

### 즉시 비용 (테스트)

| 시나리오 | 비용 |
|---------|------|
| 배포만 (중지) | ~$0.5/월 |
| 5분 테스트 | ~$0.38 |
| 1시간 (480p) | ~$2.5 |

### 월간 비용 (480p 기준)

**일 4시간, 월 30일:**

| 항목 | 비용 |
|------|------|
| MediaLive (120h) | $84 |
| CloudFront | $51 |
| S3 | $5 |
| Lambda | $0.2 |
| **합계** | **~$140/월** |

### 비용 절감 팁

**1. 즉시 중지**
```bash
# 사용 후 바로!
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RvcCJ9 \
  response.json
```

**2. 낮은 화질로 시작**
```hcl
# terraform.tfvars
video_quality = "480p"  # 720p 대비 50% 절감
```

**3. Archive 자동 삭제**
```hcl
# terraform.tfvars
archive_retention_days = 7  # 7일 후 자동 삭제
```

**4. 자동 스케줄**
```hcl
# terraform.tfvars
enable_automation_schedule = true
start_schedule = "cron(0 10 * * ? *)"  # 한국 19시
stop_schedule = "cron(0 14 * * ? *)"   # 한국 23시
```

### 실시간 비용 확인

```bash
# 이번 달 누적
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost
```

---

## 🔧 커스터마이징

### terraform.tfvars 수정

```hcl
# 프로젝트 기본 설정
project_name = "live-streaming"
environment  = "dev"
region       = "ap-northeast-2"

# 화질 설정 (비용 영향!)
video_quality = "720p"  # "480p", "720p", "1080p"

# Archive 보관 기간
archive_retention_days = 7  # 일 단위

# 자동 스케줄 (선택)
enable_automation_schedule = true
start_schedule = "cron(0 10 * * ? *)"  # UTC 10:00 = 한국 19:00
stop_schedule = "cron(0 14 * * ? *)"   # UTC 14:00 = 한국 23:00

# 알람 (선택)
enable_monitoring_alarms = true
alarm_email = "your-email@example.com"
```

**적용:**
```bash
terraform apply
```

---

## 🐛 문제 해결

### 1. 재생이 안 됨

**체크리스트:**

```bash
# ✅ 채널 상태 확인
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State
# "RUNNING"이어야 함

# ✅ 앱에서 스트리밍 중
# "LIVE" 표시, 비트레이트 전송 확인

# ✅ S3 파일 생성 확인
aws s3 ls s3://$(terraform output -raw hls_bucket_name)/live/
# index.m3u8, .ts 파일들이 보여야 함

# ✅ CloudFront 배포 완료 (첫 배포 시 10~20분)
aws cloudfront get-distribution \
  --id $(terraform output -raw cloudfront_distribution_id) \
  --query 'Distribution.Status'
# "Deployed"여야 함
```

### 2. 비용이 높음

```bash
# 채널 상태 확인
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State

# "IDLE" 또는 "STOPPED"가 아니면 즉시 중지!
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RvcCJ9 \
  response.json
```

### 3. Larix 연결 안 됨

**확인:**

1. **MediaLive RUNNING 확인**
2. **RTMP URL 정확성**
```bash
terraform output medialive_rtmp_url
# rtmp://IP:1935/live 형식
```
3. **Stream Key 정확성**
```
stream-key-1 (정확히)
```
4. **네트워크 연결**
```bash
# RTMP 포트 확인
nc -zv $(terraform output -raw medialive_input_destination | cut -d: -f3 | cut -d/ -f3) 1935
```

### 4. Terraform 오류

```bash
# 초기화 재시도
rm -rf .terraform .terraform.lock.hcl
terraform init

# 상태 확인
terraform state list

# 특정 리소스 재생성
terraform taint aws_medialive_channel.main
terraform apply
```

---

## 🗑️ 전체 삭제

```bash
cd complete-terraform/environments/dev

# S3 버킷 비우기 (필수!)
aws s3 rm s3://$(terraform output -raw hls_bucket_name) --recursive
aws s3 rm s3://$(terraform output -raw archive_bucket_name) --recursive
aws s3 rm s3://$(terraform output -raw player_bucket_name) --recursive

# 인프라 삭제
terraform destroy
```

---

## 🏆 포트폴리오 하이라이트

### 구현 기술

**AWS 서비스:**
- MediaLive (RTMP → HLS 인코딩)
- S3 (저장소)
- CloudFront (글로벌 CDN)
- Lambda (자동화)
- CloudWatch (모니터링)
- IAM (권한 관리)

**프로토콜 & 코덱:**
- RTMP (Real-Time Messaging Protocol)
- HLS (HTTP Live Streaming)
- H.264 (비디오)
- AAC (오디오)

**인프라 관리:**
- Terraform (Infrastructure as Code)
- 모듈화 설계
- 환경별 분리 (dev/prod)

### 주요 성과

**글로벌 배포:**
- CloudFront 200+ 엣지 로케이션
- 전세계 저지연 스트리밍
- HTTPS 보안 연결

**자동 화질 조정:**
- 480p/720p/1080p ABR
- 네트워크 상황 자동 적응
- 끊김 없는 재생

**비용 최적화:**
- Lambda 자동화로 83% 절감
- 필요한 시간만 운영
- S3 Lifecycle 자동 삭제

**완전 자동화:**
- 한 번 배포로 전체 인프라
- Lambda 시작/중지
- EventBridge 스케줄링

### 기술적 도전

**문제 1: MediaPackage 통합 오류**
- 해결: S3 직접 출력으로 구조 단순화
- 결과: 안정성 향상, 비용 절감

**문제 2: 높은 운영 비용**
- 해결: Lambda + EventBridge 자동화
- 결과: 83% 비용 절감

**문제 3: 글로벌 지연시간**
- 해결: CloudFront CDN 도입
- 결과: 평균 지연 50% 감소

### 시연 자료

**스크린샷:**
- AWS Console 리소스 목록
- Larix 스트리밍 화면
- 웹 플레이어 재생 화면
- CloudWatch Dashboard

**데모 영상:**
- 스트리밍 시작부터 재생까지
- 화질 자동 전환 시연
- 모니터링 Dashboard

**아키텍처 다이어그램:**
- 전체 데이터 흐름
- AWS 서비스 연결
- Phase별 구성

---

## 📚 추가 리소스

**프로젝트 문서:**
- [QUICK_START.md](QUICK_START.md) - 5분 빠른 시작
- [CLOUDFRONT_GUIDE.md](CLOUDFRONT_GUIDE.md) - CloudFront 상세

**학습 자료:**
- [AWS MediaLive](https://docs.aws.amazon.com/medialive/)
- [HLS Protocol (RFC 8216)](https://datatracker.ietf.org/doc/html/rfc8216)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

**관련 기술:**
- RTMP Specification
- H.264/AVC Video Coding
- AAC Audio Coding
- CloudFront Best Practices

---

## 📞 지원

**문제 발생 시:**
1. 위 [문제 해결](#-문제-해결) 섹션 확인
2. QUICK_START.md 재확인
3. AWS Console에서 리소스 상태 확인
4. CloudWatch Logs 확인

**비용 관리:**
- 사용 후 반드시 채널 중지
- 정기적으로 비용 확인
- Budget Alert 설정 권장

---

**만든이:** GJJANG | **날짜:** 2025 | **목적:** 포트폴리오
