# OTT 큐레이션 앱

> AI 기반 한국 OTT 콘텐츠 큐레이션 + AI 콘텐츠 관 (숏폼) 서비스

넷플릭스, 티빙, 쿠팡플레이, 왓챠, 웨이브 5개 플랫폼을 통합하고, Claude AI로 개인 맥락에 맞는 콘텐츠를 추천합니다.

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| **앱** | Flutter (Dart) + Riverpod 2.0 + GoRouter |
| **인증** | Firebase Auth (카카오/Apple/Google) |
| **API 서버** | Cloud Run · Node.js/TypeScript · Express |
| **데이터베이스** | Cloud SQL (PostgreSQL 15) + pgvector + pg_trgm |
| **스토리지** | Cloud Storage |
| **AI 추천** | Claude API + Voyage AI (임베딩) |
| **콘텐츠 데이터** | JustWatch API + TMDb API |
| **CRON** | Cloud Scheduler + Cloud Functions |
| **푸시** | Firebase Cloud Messaging |

---

## 프로젝트 구조

```
new ott curation/
├── flutter_app/          # Flutter 앱 (iOS + Android)
│   └── lib/
│       ├── core/         # 공유 레이어 (theme, network, widgets)
│       ├── features/
│       │   ├── auth/             # 로그인 (카카오/Apple/Google)
│       │   ├── home/             # 홈 + 큐레이션 섹션
│       │   ├── curation/         # AI 큐레이션 챗
│       │   ├── ai_content_hall/  # AI 숏폼 피드 + 업로드
│       │   ├── community/        # 리뷰 + 컬렉션 (예정)
│       │   └── profile/          # 프로필 (예정)
│       └── routing/      # GoRouter 설정
│
├── server/               # Cloud Run API (Node.js/TypeScript)
│   └── src/
│       ├── routes/       # REST 엔드포인트
│       ├── services/     # 비즈니스 로직 (Claude, Voyage, JustWatch, TMDb)
│       ├── middleware/   # Firebase Auth 검증
│       └── db/           # Cloud SQL 연결
│
├── db/migrations/        # PostgreSQL 스키마 (001~006)
├── functions/            # Cloud Functions (CRON 트리거)
├── scripts/              # GCP 자동화 스크립트
├── .env.example          # 환경변수 템플릿
└── SETUP.md              # 시작 가이드
```

---

## 빠른 시작

### 1단계 (직접, ~10분)

```bash
# gcloud CLI 설치
brew install google-cloud-sdk

# Google 계정 로그인 (브라우저 팝업)
gcloud auth login
gcloud auth application-default login

# GCP Console → 결제 계정 연동
# https://console.cloud.google.com/billing
```

### 2단계 (자동화 스크립트)

```bash
# 환경변수 설정
cp .env.example .env
# .env 파일에 API 키 입력 (아래 표 참고)

# GCP 전체 자동 설정 (5~10분)
chmod +x scripts/setup-gcp.sh
./scripts/setup-gcp.sh YOUR_BILLING_ACCOUNT_ID
```

스크립트가 자동으로 처리:
- GCP 프로젝트 생성 + API 12종 활성화
- Cloud SQL (PostgreSQL 15 + pgvector + pg_trgm) 생성
- DB 마이그레이션 6개 실행
- Cloud Storage 버킷 3개 생성
- Secret Manager에 API 키 등록
- Cloud Run API 서버 배포
- Cloud Scheduler CRON 4개 설정 (콘텐츠 동기화, 임베딩, 개인화, 피드 스코어)

### 3단계 (Flutter 앱)

```bash
cd flutter_app

# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod, Freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# Firebase 설정 파일 추가 (Firebase Console에서 다운로드)
# Android: android/app/google-services.json
# iOS:     ios/Runner/GoogleService-Info.plist

# 앱 실행
flutter run --dart-define=API_BASE_URL=https://YOUR_CLOUD_RUN_URL
```

---

## 필요한 API 키

`.env` 파일에 입력하세요:

| 키 | 발급처 | 비용 |
|----|--------|------|
| `TMDB_API_KEY` | [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) | 무료 |
| `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) | 유료 (사용량) |
| `VOYAGE_API_KEY` | [voyageai.com](https://www.voyageai.com) | 유료 (사용량) |
| `JUSTWATCH_API_KEY` | JustWatch 파트너십 신청 | 별도 협의 |

> JustWatch 공식 API가 없으면 비공식 GraphQL 엔드포인트를 사용합니다 (setup.sh에 포함).

---

## 핵심 기능

### 1. OTT 콘텐츠 큐레이션
- JustWatch API로 5개 OTT 플랫폼 실시간 가용성 동기화
- Claude AI 자연어 큐레이션 챗 ("비오는 날 혼자 볼 영화")
- pgvector 코사인 유사도 기반 개인화 추천
- 조화평균(harmonic mean) 평점 집계 (왓챠피디아 방식)

### 2. AI 콘텐츠 관
- AI 생성 숏폼 전용 피드 (TikTok 스타일)
- Cloud Storage signed URL 직접 업로드 (최대 60초/500MB)
- Claude Vision API 자동 모더레이션
- 피드 스코어 = engagement(40%) + freshness(30%) + personalization(20%) + diversity(10%)

### 3. 커뮤니티
- 평점 (0.5점 단위, 조화평균 집계)
- 리뷰 (스포일러 토글, 도움됨 투표)
- 컬렉션 생성 및 공유

---

## API 엔드포인트

| Method | 경로 | 기능 |
|--------|------|------|
| GET | `/api/contents` | 콘텐츠 목록 (OTT/장르 필터) |
| GET | `/api/contents/search` | 한국어 퍼지 검색 |
| GET | `/api/contents/:id` | 콘텐츠 상세 + OTT 가용성 |
| GET | `/api/curations/home` | 개인화 홈 섹션 |
| POST | `/api/curations/chat` | AI 자연어 큐레이션 |
| GET | `/api/ai-hall/feed` | AI 콘텐츠 피드 |
| POST | `/api/ai-hall/upload` | 업로드 signed URL 발급 |
| POST | `/api/users/auth/kakao` | 카카오 커스텀 토큰 발급 |
| POST | `/api/users/onboarding` | 온보딩 완료 |
| POST | `/api/users/ratings` | 평점 등록/수정 |

---

## 개발 단계

- **Phase 0** (완료): GCP 인프라 + Flutter 스캐폴드 + Auth
- **Phase 1** (진행 중): 콘텐츠 코어 — JustWatch/TMDb 동기화, 홈 화면, 검색
- **Phase 2**: AI 큐레이션 + 평점/리뷰 시스템
- **Phase 3**: AI 콘텐츠 관 — 피드, 업로드, 모더레이션
- **Phase 4**: 커뮤니티 + 폴리시 + 알림
- **Phase 5**: 베타 테스트 + 앱스토어 출시

---

## 로컬 개발 (Cloud SQL Auth Proxy)

```bash
# Cloud SQL Auth Proxy 실행 (별도 터미널)
cloud_sql_proxy --port=5433 ott-curation-app:asia-northeast3:ott-curation-db

# 서버 로컬 실행
cd server
npm install
npm run dev
```

---

## 환경변수 목록

| 변수 | 설명 |
|------|------|
| `GCP_PROJECT_ID` | GCP 프로젝트 ID |
| `GCP_REGION` | GCP 리전 (asia-northeast3) |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD` | PostgreSQL 연결 정보 |
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID |
| `ANTHROPIC_API_KEY` | Claude API 키 |
| `VOYAGE_API_KEY` | Voyage AI 임베딩 키 |
| `TMDB_API_KEY` | TMDb 콘텐츠 메타데이터 키 |
| `API_SECRET_KEY` | 내부 API 시크릿 (Cloud Scheduler용) |
