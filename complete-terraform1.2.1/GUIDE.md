# 🚀 CloudFront + 자동 플레이어 호스팅 가이드

## ✨ 새로운 기능

### 자동화된 것들
- ✅ 웹 플레이어 S3 호스팅
- ✅ HTML 자동 업로드
- ✅ CloudFront HTTPS 배포
- ✅ 자동 재생 활성화
- ✅ 전세계 CDN

### 수동 작업 필요 없음
- ❌ HTML 수동 업로드
- ❌ URL 복사/붙여넣기
- ❌ S3 정책 설정
- ❌ CORS 설정

---

## 🚀 배포 방법

### 1. 파일 압축 해제

```bash
unzip live-streaming-cloudfront.zip
cd complete-terraform/environments/dev
```

### 2. Terraform 초기화

```bash
terraform init
```

### 3. 배포 계획 확인

```bash
terraform plan
```

**확인사항:**
- Player S3 버킷 생성
- HLS CloudFront 배포
- Player CloudFront 배포

### 4. 배포 실행

```bash
terraform apply
```

`yes` 입력

**대기 시간:** 약 5~10분 (CloudFront 배포 시간)

---

## 📋 배포 후 확인

### URL 확인

```bash
# 웹 플레이어 CloudFront URL (HTTPS)
terraform output player_cloudfront_url

# HLS CloudFront URL (HTTPS)  
terraform output hls_cloudfront_url

# 웹 플레이어 S3 URL (HTTP, 백업용)
terraform output player_s3_url
```

**출력 예시:**
```
player_cloudfront_url = "https://d1234567890.cloudfront.net"
hls_cloudfront_url = "https://d0987654321.cloudfront.net/live.m3u8"
player_s3_url = "http://live-streaming-dev-player-xxx.s3-website.ap-northeast-2.amazonaws.com"
```

---

## 🎬 사용 방법

### 1. 채널 시작

```bash
aws lambda invoke --function-name live-streaming-dev-channel-control --payload eyJhY3Rpb24iOiAic3RhcnQifQ== response.json
```

**2분 대기**

### 2. 스트리밍 시작

**CameraFi Live / Larix:**
```
Server: rtmp://52.78.194.134:1935
Stream Key: stream-key-1
```

**GO LIVE** 버튼 클릭!

### 3. 웹 플레이어 접속

**CloudFront URL 복사:**
```bash
terraform output player_cloudfront_url
```

**브라우저에서 접속:**
```
https://d1234567890.cloudfront.net
```

**자동으로 재생 시작!** 🎉

---

## ✨ 자동 기능

### 페이지 로드 시
1. ✅ 올바른 HLS URL 자동 설정
2. ✅ 0.5초 후 자동 재생 시도
3. ✅ LIVE 상태 표시

### 재생 실패 시
- 🔄 자동 재연결 시도
- 🔄 미디어 오류 자동 복구
- 📊 상태 실시간 표시

---

## 🌐 CloudFront 장점

### HTTPS
- ✅ 무료 SSL 인증서
- ✅ 보안 연결
- ✅ 모던 브라우저 호환

### 속도
- ✅ 전세계 200+ 엣지 로케이션
- ✅ 자동 캐싱
- ✅ 낮은 지연시간

### 비용
- ✅ S3 직접 접근보다 저렴
- ✅ 대역폭 33% 절감
- ✅ 1TB 무료 티어 (12개월)

---

## 📊 리소스 구조

```
┌─────────────────────┐
│   휴대폰 (Larix)    │
└──────────┬──────────┘
           │ RTMP
           ↓
┌─────────────────────┐
│   AWS MediaLive     │
│   (인코딩/변환)      │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ↓           ↓
┌─────────┐ ┌─────────┐
│ S3 HLS  │ │S3 Player│
└────┬────┘ └────┬────┘
     │           │
     ↓           ↓
┌─────────┐ ┌─────────┐
│CloudFront│ │CloudFront│
│   HLS   │ │  Player │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           ↓
     ┌──────────┐
     │   시청자  │
     └──────────┘
```

---

## 🔧 커스터마이징

### HTML 수정하려면

1. `complete-terraform/player/index.html.tpl` 수정
2. `terraform apply`
3. CloudFront 캐시 무효화 (선택사항)

```bash
DIST_ID=$(terraform output -raw player_cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

---

## 💰 비용 예상

### 월 100시간 스트리밍 기준

| 서비스 | 비용 |
|--------|------|
| MediaLive | ~$250 |
| S3 저장 (HLS) | ~$0.5 |
| S3 저장 (Archive) | ~$5 |
| S3 저장 (Player) | ~$0.01 |
| CloudFront (1TB) | 무료 → $85 |
| Lambda | ~$0.2 |
| **합계** | ~$255~340/월 |

**절약 팁:**
- 사용 안 할 때 채널 중지
- Archive 자동 삭제 (7일)
- CloudFront 무료 티어 활용

---

## 🎯 외부 공유

### CloudFront URL 공유

**장점:**
- ✅ HTTPS (안전)
- ✅ 빠른 속도
- ✅ 전세계 접근

**공유 방법:**
```bash
terraform output player_cloudfront_url
```

이 URL을 카카오톡, 이메일 등으로 공유!

---

## 🐛 트러블슈팅

### 1. CloudFront 배포 실패

```bash
# 상태 확인
aws cloudfront list-distributions

# 재배포
terraform destroy -target=aws_cloudfront_distribution.player
terraform apply
```

### 2. HTML이 업데이트 안 됨

```bash
# 캐시 무효화
DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='live-streaming dev Player Distribution'].Id" --output text)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### 3. 자동 재생 안 됨

브라우저 정책상 음소거 상태에서만 자동 재생 가능
→ HTML 파일에서 `muted` 속성 유지

---

## 📝 체크리스트

배포 전:
- [ ] AWS CLI 설정 완료
- [ ] Terraform 설치 완료
- [ ] 계정 권한 확인

배포 후:
- [ ] CloudFront URL 확인
- [ ] 채널 시작
- [ ] 스트리밍 테스트
- [ ] 웹 플레이어 접속
- [ ] 자동 재생 확인

---


이제:
- ✅ HTTPS 웹 플레이어
- ✅ 자동 재생
- ✅ 전세계 CDN
- ✅ 외부 공유 가능


---

## 📞 지원

문제 발생 시:
1. `terraform plan` 오류 확인
2. AWS Console에서 리소스 확인
3. CloudWatch Logs 확인

