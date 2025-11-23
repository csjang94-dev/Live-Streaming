# ⚡ 빠른 시작 (5분)

## 1. 배포

```bash
cd complete-terraform/environments/dev

terraform init
terraform apply  # yes 입력
```

⏳ 5분 대기

---

## 2. 사용

### A. 채널 시작
```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload '{"action": "start"}' \
  response.json

# ⏳ 30초 대기
```

### B. 스트리밍

**RTMP URL:**
```bash
terraform output medialive_rtmp_url
```

**Larix/CameraFi 설정:**
```
Server: (위 URL)
Stream Key: stream-key-1
```

**GO LIVE!** 🔴

### C. 재생

```bash
# VLC
vlc $(terraform output -raw final_playback_url)

# 또는 브라우저
terraform output player_html_example > player.html
open player.html
```

### D. 중지

```bash
aws lambda invoke \
  --function-name live-streaming-dev-channel-control \
  --payload '{"action": "stop"}' \
  response.json
```

⚠️ **반드시 중지하세요!**

---

## 💰 비용

- **5분 테스트:** ~$0.38
- **1시간:** ~$1.25

---

## 🐛 문제?

### 재생 안 됨
```bash
# 채널 상태 확인
terraform output -raw medialive_channel_id | \
  xargs -I {} aws medialive describe-channel --channel-id {} --query State
```

"RUNNING"이어야 함!

---

## 📚 더 보기

- **[README.md](README.md)** - 전체 가이드

---

