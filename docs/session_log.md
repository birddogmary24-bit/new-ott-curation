# Session Log — OTT 큐레이션 앱

> 각 작업 세션의 내용, 의도, 영향도를 기록합니다.
> 최신 세션이 위에 오도록 역순 정렬합니다.

---

## SESSION-003 · 2026-02-28

### 작업 내용
**Phase 1 진행: Flutter 화면 구현 (플레이스홀더 → 실제 화면 교체)**

**신규 Flutter 피처 화면 (6개 피처)**
- `onboarding/`: 장르 선택(OnboardingGenreScreen), OTT 선택(OnboardingOttScreen), 초기 평점(OnboardingRateScreen) + 위젯(genre_chip, ott_selection_card, rating_content_tile, onboarding_progress_bar) + OnboardingProvider + 장르 상수
- `search/`: SearchScreen (검색바 + 결과 목록)
- `content_detail/`: ContentDetailScreen (backdrop_header, ott_availability_section, content_info_section, review_snippet) + ContentDetailProvider
- `community/`: CommunityScreen, CollectionDetailScreen + 위젯(review_card, collection_card) + Provider 2개 + 모델(review, collection_summary, collection_detail)
- `profile/`: ProfileScreen, ProfileEditScreen, MyRatingsScreen + 위젯(profile_header, taste_radar_chart, stats_row) + ProfileProvider + TasteProfile 엔티티/모델
- `settings/`: SettingsScreen

**공유 위젯**
- `flutter_app/lib/core/widgets/star_rating_bar.dart`: 0.5점 단위 별점 입력 위젯

**수정된 파일**
- `routing/app_router.dart`: 플레이스홀더 → 실제 화면 교체 (onboarding 3개, search, content_detail, community, collection_detail, profile 3개, settings), ContentDetailScreen 경로 파라미터 전달
- `core/network/api_client.dart`: `apiClientProvider` (Riverpod Provider<Dio>) 추가
- `features/home/data/datasources/content_remote_datasource.dart`: `getContentDetailFull()`, `rateContent()` 메서드 추가
- `core/errors/failures.dart`: `NetworkFailure`, `ServerFailure` 생성자 optional parameter 방식으로 변경

### 의도
SESSION-001에서 만든 라우터의 플레이스홀더 화면들을 실제 UI로 교체하여 앱의 전체 화면 흐름을 완성. Clean Architecture (data→domain→presentation) 레이어 구조 준수.

### 영향도
- **직접 영향**: `flutter_app/lib/features/` 하위 6개 피처 신규 + `core/` 2개 수정
- **라우팅 완성도**: _PlaceholderScreen 대부분 제거 (내 컬렉션 1개만 남음)
- **API 연결**: ContentDetailProvider, ProfileProvider, CommunityProvider가 apiClientProvider 의존

---

## SESSION-002 · 2026-02-28

### 작업 내용
- `docs/` 디렉토리 생성 및 4개 문서 초안 작성
  - `PRD.md`: 제품 비전, 핵심 Epics, 비기능 요구사항, 개발 단계
  - `feature_list.md`: F-01 ~ F-14 기능별 정책·로직·아키텍처·데이터구조 상세 기술
  - `decision_log.md`: D-001 ~ D-010 핵심 의사결정 기록 (프레임워크, DB, AI 모델, 알고리즘 등)
  - `session_log.md`: 이 파일 (세션 로그)
- `CLAUDE.md` 작성: 앞으로의 세션에서 이 문서들을 자동 업데이트하는 규칙 정의

### 의도
코드베이스는 존재하지만 제품 스펙 문서가 없어 새 세션마다 컨텍스트를 재구성해야 했음. 4개 문서를 통해:
- PRD: "왜 이걸 만드는지" 정의
- feature_list: "무엇을 어떻게 만드는지" 정의
- decision_log: "왜 이렇게 만들었는지" 추적
- session_log: "어떤 작업이 있었는지" 추적

### 영향도
- **직접 영향**: `docs/` 디렉토리 (신규), `CLAUDE.md` (신규)
- **코드 변경 없음**: 기존 코드베이스 변경 없이 문서만 추가
- **향후 세션 영향**: 이 문서들을 기준으로 작업하므로 컨텍스트 일관성 유지 가능

---

## SESSION-001 · 2026-02 (Initial Commit)

### 작업 내용
**Phase 0 완료: GCP 인프라 + 전체 스캐폴딩**

**DB (PostgreSQL 마이그레이션 6개)**
- `001`: pgvector, pg_trgm, uuid-ossp 익스텐션 + OTT 플랫폼 5개 + 장르 17개 시드 데이터
- `002`: contents 테이블 (HNSW 임베딩 인덱스) + content_availability 테이블
- `003`: profiles, user_ratings(조화평균 트리거), user_reviews, review_likes, collections, collection_items
- `004`: ai_contents (AI 콘텐츠 관) + 피드 스코어 함수
- `005`: user_taste_embeddings, curation_sections, curation_interactions + 개인화 함수
- `006`: 성능 인덱스 추가

**Backend (Node.js/TypeScript)**
- 라우트: content, curation, ai-hall, community, user, internal
- 서비스: content-sync (JustWatch + TMDb), embedding (Voyage AI), curation (Claude API)
- 미들웨어: Firebase Auth (requireAuth / optionalAuth)

**Flutter 앱**
- 인증: 카카오/Apple/Google 로그인 화면 + Provider
- 홈: 홈 화면, HeroCarousel, PlatformFilterChips, CurationSection
- 큐레이션: AI 챗 화면 + ChatBubble
- AI 콘텐츠 관: 피드 화면 + 업로드 화면
- 라우팅: GoRouter

**인프라**
- `scripts/setup-gcp.sh`: GCP 프로젝트 생성 → API 활성화 → Cloud SQL → 마이그레이션 → Cloud Storage → Secret Manager → Cloud Run 배포 → Cloud Scheduler 4개 자동화
- `scripts/bucket-lifecycle.json`: GCS 버킷 라이프사이클

### 의도
MVP를 위한 전체 아키텍처의 뼈대(스캐폴딩) 구축. 실제 API 연동·비즈니스 로직보다 구조와 데이터 모델을 먼저 확정해서 Phase 1 이후 작업의 방향을 고정.

### 영향도
- **전체 프로젝트 초기화**: 0 → 전체 코드베이스
- **DB 스키마 확정**: 추후 마이그레이션으로 변경 시 데이터 마이그레이션 필요
- **Phase 1 착수 가능**: JustWatch 실제 API 호출, TMDb 동기화 로직을 채워 넣는 작업으로 이동
