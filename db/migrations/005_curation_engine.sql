-- ============================================================
-- Migration 005: Curation Engine
-- AI 큐레이션 엔진 관련 테이블
-- ============================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 취향 임베딩
-- 평점을 매긴 콘텐츠들의 임베딩 가중 평균
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS user_taste_embeddings (
    user_id          UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    taste_embedding  VECTOR(1024),               -- 사용자 취향 벡터
    rated_count      INT DEFAULT 0,              -- 임베딩 계산에 사용된 평점 수
    last_computed    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_taste_embeddings ON user_taste_embeddings USING hnsw (taste_embedding vector_cosine_ops);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 큐레이션 섹션 (홈 화면 표시용)
-- Claude API가 생성하고 사전 계산하여 저장
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS curation_sections (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_type   TEXT NOT NULL CHECK (
        section_type IN ('trending', 'personalized', 'contextual', 'editorial', 'new_arrivals', 'by_genre')
    ),

    -- 섹션 표시 정보
    title_ko       TEXT NOT NULL,               -- '오늘 밤 볼만한 스릴러'
    subtitle_ko    TEXT,                        -- AI 생성 부제목
    ai_reason      TEXT,                        -- AI 생성 큐레이션 이유

    -- 타겟팅
    target_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,  -- NULL = 모든 사용자
    context_tags   TEXT[] DEFAULT '{}',         -- ['weekend', 'night', 'rain']
    genre_filter   TEXT,                        -- 장르 기반 섹션일 때 장르명

    -- 콘텐츠 목록
    content_ids    UUID[] NOT NULL,             -- 정렬된 콘텐츠 ID 배열

    -- 표시 설정
    layout_type    TEXT DEFAULT 'horizontal_scroll' CHECK (
        layout_type IN ('horizontal_scroll', 'grid', 'hero', 'list')
    ),
    sort_order     INT DEFAULT 0,
    is_active      BOOLEAN DEFAULT TRUE,
    expires_at     TIMESTAMPTZ,                 -- NULL이면 만료 없음

    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_curation_user   ON curation_sections(target_user_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_curation_global ON curation_sections(target_user_id, is_active, expires_at)
    WHERE target_user_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_curation_type   ON curation_sections(section_type, created_at DESC);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 큐레이션 상호작용 로그
-- 클릭/무시 데이터로 추천 품질 개선
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS curation_interactions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    curation_section_id UUID NOT NULL REFERENCES curation_sections(id) ON DELETE CASCADE,
    content_id          UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    interaction_type    TEXT NOT NULL CHECK (
        interaction_type IN ('impression', 'click', 'dismiss', 'save', 'rate')
    ),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 파티셔닝 없이 기본 인덱스 (초기 단계)
CREATE INDEX IF NOT EXISTS idx_curation_interactions_user    ON curation_interactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_curation_interactions_section ON curation_interactions(curation_section_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 취향 임베딩 계산 함수
-- 평점 기반 가중 평균
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION compute_user_taste_embedding(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_embedding  VECTOR(1024);
    v_count      INT;
BEGIN
    -- 긍정 평점(3.5점 이상)을 매긴 콘텐츠의 임베딩 가중 평균
    -- rating이 높을수록 가중치 높음
    SELECT
        COUNT(*),
        -- 가중 평균: SUM(embedding * normalized_weight) / total_weight
        -- pgvector의 avg는 산술 평균이므로 가중치를 repeated rows로 표현
        AVG(c.embedding)  -- 단순 평균 (초기 버전, 이후 가중 평균으로 개선)
    INTO v_count, v_embedding
    FROM user_ratings ur
    JOIN contents c ON c.id = ur.content_id
    WHERE ur.user_id = p_user_id
      AND ur.rating >= 3.5              -- 긍정 신호만 반영
      AND c.embedding IS NOT NULL;

    IF v_count > 0 THEN
        INSERT INTO user_taste_embeddings (user_id, taste_embedding, rated_count, last_computed)
        VALUES (p_user_id, v_embedding, v_count, NOW())
        ON CONFLICT (user_id)
        DO UPDATE SET
            taste_embedding = EXCLUDED.taste_embedding,
            rated_count     = EXCLUDED.rated_count,
            last_computed   = NOW();
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 개인화 추천 쿼리 함수
-- 사용자 취향 벡터와 콘텐츠 벡터 코사인 유사도 기반
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION get_personalized_content(
    p_user_id         UUID,
    p_platform_ids    TEXT[],   -- 사용자 구독 플랫폼 필터
    p_exclude_ids     UUID[],   -- 이미 평점/조회한 콘텐츠 제외
    p_limit           INT DEFAULT 20
)
RETURNS TABLE (
    content_id  UUID,
    similarity  DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        (1 - (c.embedding <=> ute.taste_embedding))::DECIMAL AS similarity
    FROM contents c
    CROSS JOIN user_taste_embeddings ute
    WHERE
        ute.user_id = p_user_id
        AND c.embedding IS NOT NULL
        AND (p_exclude_ids IS NULL OR c.id <> ALL(p_exclude_ids))
        AND (
            p_platform_ids IS NULL
            OR p_platform_ids = '{}'
            OR EXISTS (
                SELECT 1 FROM content_availability ca
                WHERE ca.content_id = c.id
                  AND ca.platform_id = ANY(p_platform_ids)
                  AND ca.availability_type = 'flatrate'
            )
        )
    ORDER BY similarity DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
