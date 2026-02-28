# OTT 큐레이션 앱 - 시작 가이드

## 먼저 해야 할 것 (직접, 10분 이내)

### Step 1: gcloud CLI 설치
```bash
brew install google-cloud-sdk
```
설치 후 새 터미널을 열거나:
```bash
source "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc"
```

### Step 2: Google 계정 로그인 (브라우저 팝업)
```bash
gcloud auth login
gcloud auth application-default login
```

### Step 3: 결제 계정 연동
1. https://console.cloud.google.com/billing 접속
2. 결제 계정 선택 또는 생성
3. 결제 계정 ID를 메모해둠 (예: `XXXXXX-YYYYYY-ZZZZZZ`)

---

## 나머지는 스크립트가 전부 처리

위 3단계 완료 후:

```bash
# 프로젝트 루트에서 실행
cd "new ott curation"

# 환경변수 설정 (API 키들)
cp .env.example .env
# .env 파일을 열어 API 키 입력

# GCP 전체 자동 설정 (5~10분 소요)
chmod +x scripts/setup-gcp.sh
./scripts/setup-gcp.sh YOUR_BILLING_ACCOUNT_ID
```

### 스크립트가 자동으로 처리하는 것
- ✅ GCP 프로젝트 생성
- ✅ 필요한 API 10종 활성화
- ✅ Cloud SQL PostgreSQL 인스턴스 생성 (서울 리전)
- ✅ pgvector, pg_trgm 익스텐션 활성화
- ✅ DB 스키마 마이그레이션 전부 실행
- ✅ Cloud Storage 버킷 3개 생성
- ✅ Secret Manager에 API 키 등록
- ✅ Cloud Run 서비스 배포
- ✅ Cloud Scheduler CRON 4개 설정
- ✅ Firebase 프로젝트 연동
- ✅ IAM 서비스 계정 및 권한 설정

---

## 필요한 API 키 목록

`.env` 파일에 입력할 것들:

| 키 | 발급처 | 비용 |
|----|--------|------|
| `TMDB_API_KEY` | https://www.themoviedb.org/settings/api | 무료 |
| `ANTHROPIC_API_KEY` | https://console.anthropic.com | 유료 (사용량 기반) |
| `VOYAGE_API_KEY` | https://www.voyageai.com | 유료 (사용량 기반) |
| `JUSTWATCH_API_KEY` | JustWatch 파트너십 신청 필요 | 별도 협의 |

> **JustWatch API**: 공식 파트너 API는 business 문의가 필요. 개발 단계에서는 비공식 GraphQL 엔드포인트 사용 (스크립트에 포함됨)

---

## Flutter 개발 환경

```bash
# Flutter SDK 설치 (없는 경우)
brew install --cask flutter

# 의존성 설치
cd flutter_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 에뮬레이터 실행
flutter run
```
