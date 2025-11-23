# ⚡ 빠른 시작 가이드 (5분)

## 📥 1단계: 배포

```bash
cd complete-terraform/environments/dev

terraform init
terraform apply
```

`yes` 입력 → 5분 대기

---

## 🎬 2단계: 사용

### A. 채널 시작
```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RhcnQifQ== \
  response.json

# 2분 대기 (채널 시작 중)
```

### B. 스트리밍

**RTMP URL 확인:**
```bash
terraform output medialive_rtmp_url
```

**CameraFi Live / Larix 설정:**
```
Server: (위 URL)
Stream Key: stream-key-1
```

**GO LIVE 버튼!**

### C. 시청

**플레이어 URL:**
```bash
terraform output player_cloudfront_url
```

브라우저에서 열기 → **자동 재생!**

### D. 중지

```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RvcCJ9 \
  response.json
```

---

## ✅ 체크리스트

- [ ] `terraform apply` 성공
- [ ] 채널 시작 (2분 대기)
- [ ] 앱에서 스트리밍
- [ ] 플레이어에서 재생
- [ ] 채널 중지 ⚠️

---

## 🐛 문제?

### 재생 안 됨
```bash
# 채널 상태 확인
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State

# RUNNING이어야 함
```

### 비용 걱정
```bash
# 즉시 중지!
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload eyJhY3Rpb24iOiAic3RvcCJ9 \
  response.json
```

---

## 💰 비용

- **5분 테스트:** ~$0.38
- **시간당 (480p):** ~$2.5
- **중지 상태:** ~$0.5/월

---

## 📚 더 알아보기

- **상세 가이드:** [CLOUDFRONT_GUIDE.md](CLOUDFRONT_GUIDE.md)
- **메인:** [README.md](README.md)

---

