# 🎥 AWS 라이브 스트리밍 시스템

모바일 앱에서 전 세계로 라이브 스트리밍 (완전 자동화)

---

## 📖 목차

1. [빠른 시작](#-빠른-시작)
2. [아키텍처](#-아키텍처)
3. [사용 방법](#-사용-방법)
4. [비용](#-비용)
5. [커스터마이징](#-커스터마이징)
6. [문제 해결](#-문제-해결)
7. [포트폴리오](#-포트폴리오)

---

## ⚡ 빠른 시작

```bash
cd complete-terraform/environments/dev
terraform init
terraform apply  # yes 입력
```

**3분 완료!**

**📚 다른 문서:**
- **[QUICK_START.md](QUICK_START.md)** - 5분 가이드

---

## 🏗️ 아키텍처

### 전체 구조

```
┌─────────────┐
│  Larix App  │ ← 스트리머
└──────┬──────┘
       │ RTMP
       ↓
┌──────────────────┐         ┌─────────────────┐
│   MediaLive      │←────────│ Lambda          │
│  (인코딩)        │         │ (자동화)        │
└────────┬─────────┘         └────────┬────────┘
         │ HLS                         │
         ↓                             ↓
┌──────────────────┐         ┌─────────────────┐
│  MediaPackage    │         │  EventBridge    │
│  (패키징)        │         │  (스케줄)       │
└────────┬─────────┘         └─────────────────┘
         │ HTTPS
         ↓
┌──────────────────┐         ┌─────────────────┐
│   CloudFront     │         │   CloudWatch    │
│   (CDN)          │─────────│   (모니터링)    │
└────────┬─────────┘         └─────────────────┘
         │ HTTPS
         ↓
     ┌──────┐
     │시청자 │
     └──────┘
```

### Phase별 구성

| Phase | 구성 요소 | 역할 |
|-------|----------|------|
| **1** | Network & IAM | Security Group, IAM Roles |
| **2** | Storage | S3 Archive |
| **3** | MediaPackage | HLS 패키징 |
| **4** | MediaLive | RTMP → HLS 인코딩 |
| **5** | CloudFront | 글로벌 CDN |
| **6** | Monitoring | CloudWatch Dashboard |
| **7** | Automation | Lambda 자동화 |

### 기술 스택

```
AWS: MediaLive, MediaPackage, CloudFront
IaC: Terraform
프로토콜: RTMP, HLS
코덱: H.264, AAC
자동화: Lambda, EventBridge
```

---

## 🚀 사용 방법

### 1. 채널 시작
```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload '{"action": "start"}' \
  response.json
```

### 2. 스트리밍
```bash
# RTMP URL 확인
terraform output medialive_rtmp_url

# Larix/CameraFi에 입력
# Stream Key: stream-key-1
```

### 3. 재생
```bash
# VLC로 재생
vlc $(terraform output -raw final_playback_url)
```

### 4. 중지 (중요!)
```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload '{"action": "stop"}' \
  response.json
```

---

## 💰 비용

### 즉시 비용

| 시나리오 | 비용 |
|---------|------|
| 배포만 | ~$3.60/월 |
| 5분 테스트 | ~$0.38 |
| 1시간 (480p) | ~$1.25 |

### 월간 비용 (480p, 일 4시간)

| 항목 | 비용 |
|------|------|
| MediaLive | $84 |
| CloudFront | $51 |
| MediaPackage | $10 |
| S3 | $5 |
| **합계** | **~$150/월** |

**자동화로 83% 절감!**

---

## 🔧 커스터마이징

`terraform.tfvars` 수정:

```hcl
# 화질 변경
video_quality = "720p"  # 480p, 720p, 1080p

# 자동 스케줄
enable_automation_schedule = true
start_schedule = "cron(0 10 * * ? *)"  # 한국 19시
stop_schedule = "cron(0 14 * * ? *)"   # 한국 23시
```

---

## 🐛 문제 해결

### 재생 안 됨

```bash
# 1. 채널 상태 확인
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State
# "RUNNING"이어야 함

# 2. S3 파일 확인
aws s3 ls s3://$(terraform output -raw archive_bucket_name)/

# 3. CloudFront 배포 확인 (10~20분 소요)
```

### 비용 관리

```bash
# 반드시 중지!
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload '{"action": "stop"}' \
  response.json
```

---

## 🗑️ 삭제

```bash
# S3 비우기
aws s3 rm s3://$(terraform output -raw archive_bucket_name) --recursive

# 인프라 삭제
terraform destroy
```

---

## 🏆 포트폴리오

### 구현 기술
- AWS: MediaLive, MediaPackage, CloudFront
- IaC: Terraform 모듈화
- 자동화: Lambda + EventBridge
- 모니터링: CloudWatch

### 주요 성과
- ✅ 200+ 엣지 글로벌 배포
- ✅ 적응형 비트레이트 (ABR)
- ✅ 83% 비용 절감 (자동화)
- ✅ 완전한 IaC

### 기술적 도전
1. **MediaPackage 통합** → HLS 패키징 구현
2. **비용 최적화** → Lambda 자동화
3. **글로벌 배포** → CloudFront CDN

---

## 📚 문서

- **[QUICK_START.md](QUICK_START.md)** - 5분 빠른 시작

---

## 📞 지원

문제 발생 시:
1. 위 [문제 해결](#-문제-해결) 확인
2. AWS Console에서 리소스 상태 확인
3. CloudWatch Logs 확인

---

**만든이:** GJJANG | **날짜:** 2025
