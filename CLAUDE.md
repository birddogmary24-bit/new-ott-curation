# CLAUDE.md — OTT 큐레이션 앱

Claude Code가 이 프로젝트에서 작업할 때 반드시 따르는 규칙입니다.

---

## 문서 자동 업데이트 규칙

**매 git commit 전에 아래 문서를 반드시 업데이트합니다.**

### 1. `docs/session_log.md`

커밋마다 새 세션 항목을 파일 상단(최신이 위)에 추가합니다.

```markdown
## SESSION-XXX · YYYY-MM-DD

### 작업 내용
- 무엇을 만들었는지 (파일 단위)

### 의도
왜 이 작업을 했는지, 어떤 문제를 해결하는지

### 영향도
- 직접 영향: 변경된 파일/모듈
- 연관 영향: 다른 파일/시스템에 미치는 영향
- Phase 진행상황 업데이트
```

### 2. `docs/decision_log.md`

중요한 기술·제품 의사결정이 있었을 때 추가합니다.

기준: 여러 선택지가 있었고 이유를 나중에 설명해야 하는 결정.

```markdown
## D-XXX. 결정 제목

- **날짜**: YYYY-MM
- **배경**: 왜 이 결정이 필요했나
- **검토한 선택지**: 각 선택지와 트레이드오프
- **결정**: 선택한 것
- **근거**: 왜 이걸 선택했나
- **트레이드오프**: 포기한 것
- **영향**: 어떤 코드/구조에 영향
```

### 3. `docs/PRD.md`

제품 방향, Phase 상태, 범위 변경이 있을 때 업데이트합니다.

### 4. `docs/feature_list.md`

새 기능 추가 또는 기존 기능 스펙 변경 시 해당 항목을 업데이트합니다.

---

## 프로젝트 구조 요약

```
flutter_app/lib/
  core/           # 공통 (테마, API 클라이언트, 위젯, 에러)
  features/
    auth/         # 카카오/Apple/Google 로그인
    home/         # 홈 화면 + 큐레이션 섹션
    curation/     # AI 챗 큐레이션
    ai_content_hall/ # AI 숏폼 피드 + 업로드
    community/    # 리뷰·컬렉션 (v4)
    profile/      # 프로필 (v4)
  routing/        # GoRouter

server/src/
  routes/         # REST 엔드포인트
  services/       # 비즈니스 로직 (Claude, Voyage, JustWatch, TMDb)
  middleware/     # Firebase Auth 검증
  db/             # Cloud SQL 클라이언트

db/migrations/    # 001~006 PostgreSQL 스키마
scripts/          # GCP 자동화
docs/             # 이 문서들
```

---

## 코딩 규칙

### TypeScript (서버)
- `zod`로 모든 요청 바디 검증
- DB 쿼리는 `query()` / `queryOne()` / `withTransaction()` 사용
- 인증: `requireAuth` (로그인 필수) / `optionalAuth` (로그인 선택)
- 환경변수 누락 시 기본값보다 오류 명시 선호

### Flutter (앱)
- Riverpod 2.0 (코드 생성) — `@riverpod` 어노테이션 사용
- Freezed 불변 모델
- 에러 상태는 `AsyncValue.error`로 처리
- GoRouter로 라우팅

### 공통
- 한국어 주석 허용 (사용자 도메인 관련)
- console.log → 구체적인 이모지 prefix 사용 (✅ 완료, ⚠️ 경고, ❌ 오류)

---

## Phase 현황

| Phase | 내용 | 상태 |
|-------|------|------|
| 0 | GCP 인프라 + Flutter 스캐폴드 + Auth | ✅ 완료 |
| 1 | 콘텐츠 코어 — JustWatch/TMDb 동기화, 홈, 검색 | 🔄 진행 중 |
| 2 | AI 큐레이션 + 평점/리뷰 시스템 | 📋 예정 |
| 3 | AI 콘텐츠 관 — 피드, 업로드, 모더레이션 | 📋 예정 |
| 4 | 커뮤니티 + 알림 + 폴리시 | 📋 예정 |
| 5 | 베타 테스트 + 앱스토어 출시 | 📋 예정 |

---

## 주요 외부 의존성

| 서비스 | 용도 | 환경변수 |
|--------|------|----------|
| Firebase Auth | 인증 | FIREBASE_PROJECT_ID |
| Claude API (Haiku) | 큐레이션·모더레이션 | ANTHROPIC_API_KEY |
| Voyage AI | 임베딩 (voyage-multilingual-2) | VOYAGE_API_KEY |
| TMDb API | 콘텐츠 메타데이터 | TMDB_API_KEY |
| JustWatch GraphQL | OTT 가용성 | 없음 (비공식) |
| Cloud SQL | PostgreSQL 15 + pgvector | DB_NAME, DB_USER, DB_PASSWORD |
| Cloud Storage | 영상·썸네일 | GCS_VIDEO_BUCKET, GCS_THUMBNAIL_BUCKET |
