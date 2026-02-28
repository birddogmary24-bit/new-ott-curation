# Feature List — OTT 큐레이션 앱

> 최종 수정: 2026-02-28
> 버전: v0.1

각 기능의 정책·로직·아키텍처·데이터구조·디자인을 모두 기록합니다.

---

## F-01. 인증 (Authentication)

### 개요
Firebase Auth 기반의 소셜 로그인. 카카오·Apple·Google 3종 지원.

### 지원 로그인 방식
| 방식 | 구현 | 비고 |
|------|------|------|
| 카카오 | 카카오 SDK → 액세스 토큰 → 서버에서 Firebase Custom Token 발급 | 한국 MAU 타겟 최우선 |
| Apple | Firebase Auth 네이티브 | iOS 심사 필수 요건 |
| Google | Firebase Auth 네이티브 | 안드로이드 기본 옵션 |

### 인증 플로우
```
[앱] 카카오 SDK 로그인
  → kakao_access_token 획득
  → POST /api/users/auth/kakao { kakao_access_token }
  → [서버] Kakao API /v2/user/me 로 검증
  → Firebase Admin SDK로 Custom Token 생성 (uid: kakao_{kakaoId})
  → [앱] Firebase signInWithCustomToken
  → Firebase ID Token 획득
  → 이후 모든 API 호출 헤더: Authorization: Bearer {firebaseIdToken}
```

### 데이터 구조
```sql
-- Firebase UID는 서버가 받은 후 profiles 테이블과 연동
profiles (
  id            UUID PK,
  firebase_uid  TEXT UNIQUE,  -- Firebase Auth의 uid
  email         TEXT,
  nickname      TEXT DEFAULT '익명',
  avatar_url    TEXT,
  ...
)
```

### 정책
- 첫 로그인 시 profiles 레코드 자동 생성 (nickname: Firebase displayName or 'user_{timestamp}')
- 온보딩 미완료 사용자는 홈 진입 후 온보딩 화면으로 redirect
- Firebase ID Token 만료 주기: 1시간 (앱에서 자동 갱신)
- 서버 미들웨어: `requireAuth` (401 반환), `optionalAuth` (userId를 null로 허용)

---

## F-02. 온보딩 (Onboarding)

### 개요
첫 로그인 후 취향 수집. 이 데이터로 초기 개인화 큐레이션 시작.

### 수집 항목
1. **선호 OTT 플랫폼** (1개 이상 선택) — 이후 기본 필터로 사용
2. **선호 장르** (1개 이상 선택)
3. **초기 평점 (선택사항)** — 잘 아는 콘텐츠에 미리 평점 → cold-start 해소

### API
```
POST /api/users/onboarding
{
  preferred_genres:    ["드라마", "스릴러"],
  preferred_platforms: ["netflix", "tving"],
  initial_ratings: [
    { content_id: "uuid", rating: 4.5 }
  ]
}
```

### 정책
- `onboarding_completed = TRUE` 로 변경 후 취향 임베딩 비동기 계산
- 초기 평점이 없어도 온보딩 완료 처리 가능 (추천은 글로벌 트렌딩으로 시작)
- 온보딩은 한 번만. 이후 취향 변경은 프로필 설정에서

---

## F-03. 콘텐츠 목록 & 검색

### 개요
5개 OTT의 통합 콘텐츠 브라우저. 필터·정렬·한국어 퍼지 검색.

### 필터 옵션
- **플랫폼**: netflix / tving / coupang_play / wavve / watcha (복수 선택)
- **장르**: 17개 장르 (복수 선택)
- **타입**: movie / tv

### 정렬 옵션
- `rating`: 우리 앱 평균 평점 DESC
- `new`: 출시일 DESC
- `trending`: 평점 수 DESC (= 인기도)

### 검색 (pg_trgm 기반)
```sql
WHERE
  c.title_ko % $1              -- 한국어 퍼지 유사도 (threshold: 0.3)
  OR c.title_en ILIKE $2       -- 영문 부분 일치
  OR c.keywords && ARRAY[$1]   -- 키워드 배열 매칭
  OR c.cast_names && ARRAY[$1] -- 출연진 이름 매칭
ORDER BY similarity(c.title_ko, $1) DESC
```

### API
```
GET /api/contents?platforms=netflix,tving&genres=드라마&type=tv&sort=rating&page=1&limit=20
GET /api/contents/search?q=오징어게임&limit=20
GET /api/contents/:id
```

### 콘텐츠 상세 응답 추가 항목
- `availability[]`: 플랫폼별 가용성 (요금제 타입, 가격, 딥링크 URL, 화질)
- `similar[]`: pgvector 코사인 유사도 상위 5개
- `user_rating`: 현재 사용자의 평점 (로그인 시)

### 데이터 구조 (주요 컬럼)
```sql
contents (
  id               UUID PK,
  tmdb_id          INT UNIQUE,
  content_type     TEXT,          -- 'movie' | 'tv'
  title_ko         TEXT,
  overview_ko      TEXT,
  poster_url       TEXT,
  genres           TEXT[],        -- GIN 인덱스
  cast_names       TEXT[],        -- GIN 인덱스
  keywords         TEXT[],        -- GIN 인덱스
  mood_tags        TEXT[],        -- AI 추출 분위기 태그
  our_avg_rating   DECIMAL(3,2),  -- 조화평균
  total_ratings    INT,
  embedding        VECTOR(1024)   -- HNSW 인덱스
)

content_availability (
  content_id       UUID FK → contents,
  platform_id      TEXT FK → ott_platforms,
  availability_type TEXT,  -- 'flatrate' | 'rent' | 'buy' | 'free' | 'ads'
  price            INT,    -- 원화 (flatrate이면 NULL)
  quality          TEXT,   -- 'sd' | 'hd' | '4k'
  deep_link_url    TEXT,
  UNIQUE(content_id, platform_id, availability_type)
)
```

---

## F-04. JustWatch / TMDb 콘텐츠 동기화

### 개요
JustWatch 비공식 GraphQL API로 한국 OTT 가용성을 수집하고, TMDb API로 상세 메타데이터를 보강.

### 동기화 플로우
```
Cloud Scheduler (매일 01:00 KST)
  → POST /api/internal/sync-content (API_SECRET_KEY 인증)
  → JustWatch GraphQL: popularTitles(country: KR, providers: [8,234,337,356,100])
  → 각 콘텐츠별 TMDb ID 추출
  → TMDb /{type}/{id}?append_to_response=credits (언어: ko-KR)
  → contents UPSERT (tmdb_id 기준 충돌 처리)
  → content_availability DELETE → INSERT (가용성 전체 갱신)
```

### JustWatch Provider IDs (한국)
| 플랫폼 | ID |
|---------|-----|
| Netflix | 8 |
| 티빙 | 234 |
| 쿠팡플레이 | 337 |
| 웨이브 | 356 |
| 왓챠 | 100 |

### 정책
- TMDb API 레이트 리밋: 25ms 딜레이 (40 req/s)
- TMDb ID 없는 콘텐츠는 동기화 스킵
- 동기화 1회당 최대 500개 처리 (JustWatch 페이지네이션 미구현 시 현재 제한)
- 동기화 실패 개별 콘텐츠는 로그만 남기고 계속 진행

---

## F-05. AI 임베딩 생성

### 개요
Voyage AI `voyage-multilingual-2` 모델로 콘텐츠 임베딩(1024차원) 생성. 의미 검색 및 개인화 추천에 사용.

### 콘텐츠 임베딩 텍스트 구성
```
{title_ko}. {overview_ko}. 장르: {genres.join(', ')}. 분위기: {mood_tags.join(', ')}
```

### 배치 처리
```
Cloud Scheduler (매일 05:00 KST)
  → POST /api/internal/generate-embeddings
  → embedding IS NULL 인 콘텐츠 100개씩 처리
  → Voyage AI 배치당 8개 (레이트 리밋: 200ms 딜레이)
  → UPDATE contents SET embedding = $1
```

### 사용자 취향 임베딩
```
trigger: 평점 등록/수정 후 비동기 실행
  → SELECT 긍정 평점(≥3.5) 콘텐츠 임베딩
  → AVG(embedding) → user_taste_embeddings UPSERT
```

### 데이터 구조
```sql
user_taste_embeddings (
  user_id         UUID PK FK → profiles,
  taste_embedding VECTOR(1024),  -- HNSW 인덱스
  rated_count     INT,
  last_computed   TIMESTAMPTZ
)
```

---

## F-06. AI 자연어 큐레이션 챗

### 개요
사용자가 자연어로 상황/기분을 입력하면 Claude가 의도를 분석하고 pgvector로 의미 유사도 검색 후 추천.

### 처리 파이프라인
```
[사용자 입력] "비오는 날 혼자 볼 로맨스"
  ↓
[Claude Haiku] 의도 분석 → JSON
  {
    search_text: "비, 비오는날, 고독, 로맨스, 멜로, 감성적인",
    content_type: "movie",
    genres: ["로맨스"],
    mood: "센치하고 감성적인",
    section_title: "빗소리와 함께하는 감성 로맨스"
  }
  ↓
[Voyage AI] search_text → 1024d 임베딩
  ↓
[PostgreSQL] pgvector 코사인 유사도 검색 (LIMIT 20)
  + 구독 플랫폼 필터
  + 이미 평가한 콘텐츠 제외
  ↓
[Claude Haiku] 큐레이션 이유 생성 (50자 이내 친근한 한국어)
  ↓
[응답] { contents[], ai_reason, section_title }
```

### API
```
POST /api/curations/chat
{ prompt: "비오는 날 혼자 볼 로맨스", platforms: ["netflix", "tving"] }

Response:
{
  data: {
    contents: [{ id, title_ko, poster_url, our_avg_rating, ... }],
    ai_reason: "빗소리와 잘 어울리는 감성적인 로맨스를 골랐어요.",
    section_title: "빗소리와 함께하는 감성 로맨스"
  }
}
```

### 모델 선택 근거
- 의도 분석: `claude-haiku-4-5` (빠름, 저렴, JSON 출력 안정적)
- 큐레이션 이유: `claude-haiku-4-5` (짧은 생성, 저렴)

### 정책
- 입력 2자 이상, 200자 이하
- JSON 파싱 실패 시 원본 텍스트로 직접 임베딩 검색 (폴백)
- 인증 없이도 사용 가능 (optionalAuth) — 단, 이미 평가한 콘텐츠 필터링은 로그인 시만

---

## F-07. 홈 화면 큐레이션 섹션

### 개요
사전 계산된 섹션 데이터를 홈에 표시. 로그인 사용자는 개인화 섹션 + 글로벌 섹션, 비로그인은 글로벌 섹션만.

### 섹션 타입
| 타입 | 설명 | 계산 주기 |
|------|------|-----------|
| `trending` | 평점 수 기준 인기작 | 매일 03:00 |
| `new_arrivals` | 30일 내 신규 콘텐츠 | 매일 03:00 |
| `by_genre` | 장르별 인기 (5개 장르) | 매일 03:00 |
| `personalized` | 개인 취향 벡터 기반 | 매일 03:00 |
| `contextual` | 시간/날씨 맥락 기반 | (v2 예정) |

### 레이아웃 타입
- `hero`: 상단 대형 배너 캐러셀
- `horizontal_scroll`: 가로 스크롤 카드 목록
- `grid`: 2열 그리드
- `list`: 세로 목록

### 개인화 계산 (야간 배치)
```
매일 03:00 → 최근 7일 내 활성 사용자 최대 1000명
  → get_personalized_content(userId, platformIds, NULL, 20) (DB 함수)
  → Claude Haiku로 섹션 제목 생성
  → curation_sections UPSERT (이전 섹션 is_active=FALSE → 신규 삽입)
  → expires_at: 24시간 후
```

### 데이터 구조
```sql
curation_sections (
  id             UUID PK,
  section_type   TEXT,        -- trending | personalized | ...
  title_ko       TEXT,
  ai_reason      TEXT,
  target_user_id UUID,        -- NULL = 모든 사용자
  content_ids    UUID[],      -- 정렬된 콘텐츠 배열
  layout_type    TEXT,
  sort_order     INT,
  is_active      BOOLEAN,
  expires_at     TIMESTAMPTZ
)
```

### 취향 프로필 API
```
GET /api/curations/taste-profile (인증 필요)
Response: {
  genre_distribution: [{ genre, count, avg_rating }],
  platform_distribution: [{ platform_id, name_ko, watched_count }],
  rating_stats: { total, avg_rating, min_rating, max_rating }
}
```

---

## F-08. 평점 시스템

### 개요
0.5점 단위 (0.5 ~ 5.0). 집계는 조화평균(왓챠피디아 방식).

### 조화평균 공식
```
조화평균 = n / SUM(1/rating_i)
```
- 극단값(별점 테러)의 영향을 산술평균보다 적게 받음
- DB 트리거로 실시간 갱신 (`update_content_rating`)

### API
```
POST /api/users/ratings
{ content_id: "uuid", rating: 4.5 }  -- 0.5 배수만 허용

GET /api/users/ratings?page=1&limit=30
```

### 정책
- 사용자당 콘텐츠 1개 평점 (UNIQUE 제약, upsert)
- 평점 등록 후 취향 임베딩 비동기 재계산 (computeUserTasteEmbedding)
- 평점 삭제 기능: v2 예정

---

## F-09. 리뷰 시스템

### 개요
텍스트 리뷰. 스포일러 토글. 좋아요(도움됨) 투표.

### 정책
- 최소 10자, 최대 2000자
- 사용자당 콘텐츠 1개 리뷰 (수정 가능)
- 스포일러 포함 리뷰는 접혀서 표시 (클릭 시 펼침)
- 리뷰 좋아요는 다른 사용자의 리뷰에만 가능 (자기 리뷰 불가 — 서버 정책 추가 필요)

### 데이터 구조
```sql
user_reviews (
  id               UUID PK,
  user_id          UUID FK,
  content_id       UUID FK,
  body             TEXT,           -- 10~2000자
  contains_spoiler BOOLEAN,
  like_count       INT,            -- 트리거로 자동 갱신
  UNIQUE(user_id, content_id)
)

review_likes (
  user_id   UUID FK,
  review_id UUID FK,
  UNIQUE(user_id, review_id)
)
```

---

## F-10. 컬렉션

### 개요
사용자가 콘텐츠를 큐레이션해서 공유 가능한 목록 만들기.

### 정책
- 제목: 2~100자
- 공개/비공개 설정
- 아이템 추가 시 노트 남기기 가능
- 컬렉션 좋아요 가능
- item_count, like_count 트리거로 자동 갱신

### 데이터 구조
```sql
collections (
  id              UUID PK,
  user_id         UUID FK,
  title           TEXT,
  description     TEXT,
  cover_image_url TEXT,
  is_public       BOOLEAN DEFAULT TRUE,
  like_count      INT,
  item_count      INT
)

collection_items (
  collection_id UUID FK,
  content_id    UUID FK,
  sort_order    INT,
  note          TEXT,         -- "이 영화 때문에 이 컬렉션 만들었어요"
  UNIQUE(collection_id, content_id)
)
```

---

## F-11. AI 콘텐츠 관 (AI Hall)

### 개요
AI 생성 숏폼 전용 피드. TikTok 스타일 세로 스크롤. 업로드→모더레이션→피드 노출 파이프라인.

### 업로드 플로우
```
[앱] POST /api/ai-hall/upload (메타데이터 + 파일 정보)
  → [서버] ai_contents 레코드 생성 (moderation_status: 'pending')
  → Signed URL 발급 (영상 30분 유효, 썸네일 30분 유효)
  → [앱] Signed URL로 Cloud Storage에 직접 PUT 업로드
  → [앱] POST /api/ai-hall/:id/upload-complete
  → [서버] video_url / thumbnail_url 업데이트
  → 비동기: moderateAndActivate()
      → Claude Haiku Vision으로 썸네일 모더레이션
      → 승인: moderation_status='approved' + 임베딩 생성
      → 거절: moderation_status='rejected' + reason 저장
```

### 업로드 제한
| 항목 | 제한 |
|------|------|
| 최대 길이 | 60초 |
| 최대 파일 크기 | 500MB |
| 지원 형식 | mp4, mov, webm |
| 콘텐츠 타입 | short_video / clip / trailer_remix / highlight / fan_edit |
| 태그 | 최대 10개 |

### 피드 스코어 알고리즘
```
score = engagement(40%) + freshness(30%) + personalization(20%) + diversity(10%)

engagement = LN(1 + likes*3 + comments*5 + shares*7 + views*0.1)  ← DB 계산
freshness  = 1 / (1 + hours_old / 24)                              ← DB 계산
personalization = (1 - cosine_distance(ac.embedding, user.taste_embedding)) * 0.2  ← 쿼리 시
diversity  = 미구현 (v2 예정)
```

### 피드 API
```
GET /api/ai-hall/feed?cursor={timestamp}&limit=20
- 커서 기반 페이지네이션 (created_at 기준)
- 로그인 시: is_liked 포함, personalization_boost 적용
- moderation_status='approved' AND is_active=TRUE 만 노출
```

### 모더레이션 판단 기준 (Claude Vision)
- 성적 콘텐츠
- 폭력 (과도한)
- 혐오 발언·이미지
- 개인정보 노출 (얼굴, 번호판 등)
- 판단 불가 시 → pending 유지 (수동 검토)

### 소셜 기능
- 좋아요 (토글) — ai_content_likes
- 댓글 (최대 500자, 스레드 1depth) — ai_content_comments
- 댓글 좋아요 — (v2 예정)

---

## F-12. 큐레이션 상호작용 로그

### 개요
홈 큐레이션 섹션의 노출·클릭·무시 데이터를 수집해 추천 품질 개선에 활용.

### 이벤트 타입
| 타입 | 의미 |
|------|------|
| `impression` | 섹션에서 콘텐츠 노출됨 |
| `click` | 콘텐츠 상세 진입 |
| `dismiss` | 해당 추천 무시 (스와이프 등) |
| `save` | 컬렉션에 저장 |
| `rate` | 평점 등록 |

### API
```
POST /api/curations/interaction (인증 필요)
{ curation_section_id: "uuid", content_id: "uuid", interaction_type: "click" }
```

---

## F-13. 알림 (Push Notification)

> v4 예정 (Firebase Cloud Messaging)

- 새 추천 섹션 갱신 알림
- 내 AI 콘텐츠 모더레이션 결과
- 리뷰/컬렉션 좋아요

---

## F-14. 내부 API (Internal Routes)

Cloud Scheduler에서 API_SECRET_KEY로 호출하는 배치 엔드포인트.

| 엔드포인트 | 주기 | 기능 |
|-----------|------|------|
| POST /api/internal/sync-content | 매일 01:00 | JustWatch/TMDb 동기화 |
| POST /api/internal/generate-embeddings | 매일 05:00 | 콘텐츠 임베딩 생성 |
| POST /api/internal/compute-curations | 매일 03:00 | 개인화 섹션 사전 계산 |
| POST /api/internal/refresh-feed-scores | 15분마다 | AI 콘텐츠 피드 스코어 갱신 |

### 인증
```
X-Internal-Secret: {API_SECRET_KEY}
```
