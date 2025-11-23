# 📋 Versioning (변경 이력)

---

## 📥 v1.2.1 (현재)

### ✨ 변경 사항
- HTML 배포 방식 변경: 로컬 파일 → S3 + CloudFront 호스팅
- 웹 플레이어 자동 배포 (Terraform으로 관리)
- CloudFront HTTPS 지원

### ➕ 추가
| 유형 | 이름 | 설명 |
|------|------|------|
| File | `player/index.html.tpl` | HTML 템플릿 (Terraform 변수 지원) |
| Resource | `aws_s3_bucket.player` | 웹 플레이어 호스팅 버킷 |
| Resource | `aws_cloudfront_distribution.player` | 플레이어 CDN 배포 |
| Resource | `aws_cloudfront_distribution.hls` | HLS CDN 배포 |
| Resource | `null_resource.update_cloudfront_url` | CloudFront URL 자동 업데이트 |

### ➖ 삭제
| 유형 | 이름 | 이유 |
|------|------|------|
| File | `live-stream-player.html` | 템플릿으로 대체 |
| File | `PLAYER_GUIDE.md` | README에 통합 |

### 🔧 수정
| 파일 | 변경 내용 |
|------|----------|
| `modules/storage/main.tf` | Player 버킷 추가, HLS Public Access 제거 |
| `modules/storage/outputs.tf` | Player 출력 추가 |
| `environments/dev/main.tf` | CloudFront 배포 추가 |
| `environments/dev/outputs.tf` | CloudFront URL 출력 추가 |

---

## 📥 v1.2.0

### ✨ 변경 사항
- MediaPackage 제거 → S3 직접 출력으로 단순화
- 안정성 향상, 비용 절감

### ➕ 추가
| 유형 | 이름 | 설명 |
|------|------|------|
| File | `live-stream-player.html` | 웹 플레이어 (로컬 파일) |
| File | `PLAYER_GUIDE.md` | 플레이어 사용 가이드 |

### ➖ 삭제
| 유형 | 이름 | 이유 |
|------|------|------|
| Module | `modules/mediapackage/` | S3 직접 출력으로 대체 |
| Resource | `aws_media_package_channel` | 불필요 |

### 🔧 수정
| 파일 | 변경 내용 |
|------|----------|
| `modules/medialive/main.tf` | 출력을 MediaPackage → S3로 변경 |
| `modules/storage/main.tf` | HLS 버킷 Public Access 추가 |

---

## 📥 v1.1.0

### ✨ 변경 사항
- Lambda 자동화 추가
- EventBridge 스케줄링 지원

### ➕ 추가
| 유형 | 이름 | 설명 |
|------|------|------|
| Module | `modules/automation/` | Lambda 시작/중지 함수 |
| Resource | `aws_lambda_function` | 채널 제어 |
| Resource | `aws_cloudwatch_event_rule` | 스케줄 (선택) |

---

## 📥 v1.0.0 (초기 버전)

### ✨ 기능
- MediaLive RTMP 입력
- MediaPackage HLS 출력
- CloudFront CDN
- CloudWatch 모니터링
- S3 Archive 저장

### 📦 모듈 구성
```
modules/
├── network/        # VPC, Security Group
├── iam/           # IAM Roles
├── storage/       # S3 Buckets
├── mediapackage/  # HLS Packaging
├── medialive/     # RTMP Encoding
├── cloudfront/    # CDN
└── monitoring/    # CloudWatch
```

---

## 📊 버전 비교

| 버전 | MediaPackage | 웹 플레이어 | CloudFront | Lambda |
|------|-------------|------------|------------|--------|
| v1.0.0 | ✅ | ❌ | ✅ (MP용) | ❌ |
| v1.1.0 | ✅ | ❌ | ✅ (MP용) | ✅ |
| v1.2.0 | ❌ | ✅ (로컬) | ❌ | ✅ |
| **v1.2.1** | ❌ | ✅ (S3) | ✅ (HLS+Player) | ✅ |

---

## 🔮 예정 (v1.3.0)

- [ ] 저지연 모드 (Low Latency)
- [ ] 다중 화질 지원 (ABR)
- [ ] 시청자 수 카운트
- [ ] 채팅 기능

---

**최종 업데이트:** 2025
