-- ============================================================
-- Migration 002: Content Tables
-- ============================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 콘텐츠 (영화/드라마) 메인 테이블
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS contents (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tmdb_id          INT UNIQUE,                 -- TMDb ID (중복 방지)
    justwatch_id     TEXT,                       -- JustWatch 콘텐츠 ID
    content_type     TEXT NOT NULL CHECK (content_type IN ('movie', 'tv')),

    -- 제목
    title_ko         TEXT NOT NULL,
    title_en         TEXT,
    title_original   TEXT,

    -- 설명
    overview_ko      TEXT,
    overview_en      TEXT,

    -- 이미지
    poster_url       TEXT,                       -- TMDb 포스터 URL
    backdrop_url     TEXT,                       -- 배경 이미지 URL

    -- 날짜/기간
    release_date     DATE,                       -- 영화 개봉일 / 드라마 첫 방영일
    runtime_minutes  INT,                        -- 영화: 상영시간, 드라마: 회당 시간
    episode_count    INT,                        -- 드라마 전체 에피소드 수
    season_count     INT,                        -- 드라마 시즌 수

    -- 분류
    genres           TEXT[] DEFAULT '{}',        -- ['드라마', '스릴러']
    mood_tags        TEXT[] DEFAULT '{}',        -- ['감동적인', '긴장감', '따뜻한'] - AI 추출
    keywords         TEXT[] DEFAULT '{}',        -- 검색용 키워드 - AI 추출
    cast_names       TEXT[] DEFAULT '{}',        -- 주요 출연진 이름 (상위 5명)
    director         TEXT,

    -- 평점
    tmdb_rating      DECIMAL(3,1),               -- TMDb 평점 (0~10)
    our_avg_rating   DECIMAL(3,2) DEFAULT 0,     -- 우리 앱 조화평균 평점 (0~5)
    total_ratings    INT DEFAULT 0,              -- 우리 앱 평점 수
    our_review_count INT DEFAULT 0,              -- 리뷰 수

    -- AI 임베딩 (pgvector) - 유사도 검색에 사용
    embedding        VECTOR(1024),

    -- 동기화 메타데이터
    last_synced_at   TIMESTAMPTZ,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_contents_tmdb_id       ON contents(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_contents_content_type  ON contents(content_type);
CREATE INDEX IF NOT EXISTS idx_contents_genres        ON contents USING GIN(genres);
CREATE INDEX IF NOT EXISTS idx_contents_keywords      ON contents USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_contents_mood_tags     ON contents USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS idx_contents_cast_names    ON contents USING GIN(cast_names);
-- 한국어 퍼지 검색용 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_contents_title_ko_trgm ON contents USING GIN(title_ko gin_trgm_ops);
-- pgvector HNSW 인덱스 (코사인 유사도 ANN 검색)
CREATE INDEX IF NOT EXISTS idx_contents_embedding     ON contents USING hnsw (embedding vector_cosine_ops);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contents_updated_at
    BEFORE UPDATE ON contents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- OTT 플랫폼 가용성 테이블
-- 어떤 OTT에서 해당 콘텐츠를 볼 수 있는지
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS content_availability (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id       UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    platform_id      TEXT NOT NULL REFERENCES ott_platforms(id),
    availability_type TEXT NOT NULL CHECK (
        availability_type IN ('flatrate', 'rent', 'buy', 'free', 'ads')
    ),
    price            INT,                        -- 가격 (원, flatrate이면 NULL)
    quality          TEXT,                       -- 'sd', 'hd', '4k'
    deep_link_url    TEXT,                       -- 해당 플랫폼의 콘텐츠 직접 링크
    available_from   DATE,
    available_until  DATE,
    last_checked_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(content_id, platform_id, availability_type)
);

CREATE INDEX IF NOT EXISTS idx_availability_content  ON content_availability(content_id);
CREATE INDEX IF NOT EXISTS idx_availability_platform ON content_availability(platform_id);
CREATE INDEX IF NOT EXISTS idx_availability_type     ON content_availability(availability_type);
