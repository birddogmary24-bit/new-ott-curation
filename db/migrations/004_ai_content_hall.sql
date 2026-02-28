-- ============================================================
-- Migration 004: AI Content Hall
-- AI로 생성된 숏폼 콘텐츠 공간
-- ============================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AI 생성 콘텐츠 메인 테이블
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ai_contents (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- 콘텐츠 정보
    title               TEXT NOT NULL CHECK (length(title) >= 2 AND length(title) <= 100),
    description         TEXT,
    content_type        TEXT NOT NULL CHECK (
        content_type IN ('short_video', 'clip', 'trailer_remix', 'highlight', 'fan_edit')
    ),

    -- 원본 OTT 콘텐츠 연결 (옵션)
    related_content_id  UUID REFERENCES contents(id) ON DELETE SET NULL,

    -- 미디어 파일
    video_url           TEXT NOT NULL,            -- Cloud Storage 서명된 URL 경로
    thumbnail_url       TEXT,
    duration_seconds    INT CHECK (duration_seconds > 0 AND duration_seconds <= 60),
    file_size_bytes     BIGINT,

    -- AI 메타데이터
    ai_tool_used        TEXT,                     -- 'runway', 'sora', 'kling', 'midjourney' 등
    ai_generation_prompt TEXT,                    -- 생성에 사용한 프롬프트 (공유 선택)

    -- 소셜 지표
    view_count          INT DEFAULT 0,
    like_count          INT DEFAULT 0,
    comment_count       INT DEFAULT 0,
    share_count         INT DEFAULT 0,

    -- 모더레이션
    moderation_status   TEXT DEFAULT 'pending' CHECK (
        moderation_status IN ('pending', 'approved', 'rejected', 'flagged')
    ),
    moderation_reason   TEXT,
    moderated_at        TIMESTAMPTZ,

    -- 피드 알고리즘
    -- score = engagement(40%) + freshness(30%) + personalization(20%) + diversity(10%)
    engagement_score    DECIMAL(12,4) DEFAULT 0,
    embedding           VECTOR(1024),             -- 피드 개인화용 임베딩
    tags                TEXT[] DEFAULT '{}',

    -- 상태
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_ai_contents_user       ON ai_contents(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_contents_moderation ON ai_contents(moderation_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_contents_feed       ON ai_contents(moderation_status, engagement_score DESC)
    WHERE moderation_status = 'approved' AND is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_ai_contents_embedding  ON ai_contents USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_ai_contents_tags       ON ai_contents USING GIN(tags);

CREATE TRIGGER ai_contents_updated_at
    BEFORE UPDATE ON ai_contents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AI 콘텐츠 좋아요
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ai_content_likes (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ai_content_id  UUID NOT NULL REFERENCES ai_contents(id) ON DELETE CASCADE,
    created_at     TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, ai_content_id)
);

CREATE INDEX IF NOT EXISTS idx_ai_likes_content ON ai_content_likes(ai_content_id);

-- 좋아요 수 자동 업데이트
CREATE OR REPLACE FUNCTION update_ai_content_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ai_contents SET like_count = like_count + 1 WHERE id = NEW.ai_content_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ai_contents SET like_count = like_count - 1 WHERE id = OLD.ai_content_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_content_likes_count
    AFTER INSERT OR DELETE ON ai_content_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_content_like_count();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AI 콘텐츠 댓글 (스레드 지원)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ai_content_comments (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ai_content_id  UUID NOT NULL REFERENCES ai_contents(id) ON DELETE CASCADE,
    parent_id      UUID REFERENCES ai_content_comments(id) ON DELETE CASCADE,
    body           TEXT NOT NULL CHECK (length(body) >= 1 AND length(body) <= 500),
    like_count     INT DEFAULT 0,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_comments_content ON ai_content_comments(ai_content_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ai_comments_parent  ON ai_content_comments(parent_id);

-- 댓글 수 자동 업데이트
CREATE OR REPLACE FUNCTION update_ai_content_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.parent_id IS NULL THEN
        UPDATE ai_contents SET comment_count = comment_count + 1 WHERE id = NEW.ai_content_id;
    ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NULL THEN
        UPDATE ai_contents SET comment_count = comment_count - 1 WHERE id = OLD.ai_content_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_comments_count
    AFTER INSERT OR DELETE ON ai_content_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_content_comment_count();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 피드 스코어 계산 함수
-- 15분마다 Cloud Scheduler가 호출
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION compute_feed_engagement_score(
    p_likes    INT,
    p_comments INT,
    p_shares   INT,
    p_views    INT,
    p_created_at TIMESTAMPTZ
) RETURNS DECIMAL AS $$
DECLARE
    v_hours_old    DECIMAL;
    v_engagement   DECIMAL;
    v_freshness    DECIMAL;
BEGIN
    v_hours_old  := EXTRACT(EPOCH FROM (NOW() - p_created_at)) / 3600;
    v_engagement := LN(1 + (p_likes * 3 + p_comments * 5 + p_shares * 7 + p_views * 0.1));
    v_freshness  := 1.0 / (1 + v_hours_old / 24.0);

    -- engagement(40%) + freshness(30%) 의 합산 (personalization, diversity는 쿼리 시 적용)
    RETURN (v_engagement * 0.4) + (v_freshness * 0.3);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 전체 스코어 배치 업데이트 (Cloud Scheduler 호출)
CREATE OR REPLACE FUNCTION refresh_all_feed_scores()
RETURNS VOID AS $$
BEGIN
    UPDATE ai_contents
    SET engagement_score = compute_feed_engagement_score(
        like_count, comment_count, share_count, view_count, created_at
    )
    WHERE moderation_status = 'approved' AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql;
