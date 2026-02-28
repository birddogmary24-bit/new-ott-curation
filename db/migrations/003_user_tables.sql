-- ============================================================
-- Migration 003: User Tables
-- ============================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 프로필
-- Firebase Auth의 uid를 기반으로 연동
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS profiles (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid           TEXT UNIQUE NOT NULL,   -- Firebase Auth UID
    email                  TEXT,
    nickname               TEXT NOT NULL DEFAULT '익명',
    avatar_url             TEXT,
    bio                    TEXT,

    -- 취향 설정 (온보딩에서 수집)
    preferred_genres       TEXT[] DEFAULT '{}',    -- ['드라마', '스릴러', '로맨스']
    preferred_platforms    TEXT[] DEFAULT '{}',    -- ['netflix', 'tving', 'coupang_play']
    taste_keywords         TEXT[] DEFAULT '{}',    -- 사용자 정의 취향 태그

    -- 통계
    total_ratings          INT DEFAULT 0,
    total_reviews          INT DEFAULT 0,
    total_collections      INT DEFAULT 0,

    -- 상태
    onboarding_completed   BOOLEAN DEFAULT FALSE,
    is_active              BOOLEAN DEFAULT TRUE,

    created_at             TIMESTAMPTZ DEFAULT NOW(),
    updated_at             TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_firebase_uid ON profiles(firebase_uid);

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 평점 (0.5점 단위, 0.5~5.0)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS user_ratings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content_id  UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    rating      DECIMAL(2,1) NOT NULL CHECK (rating >= 0.5 AND rating <= 5.0),
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, content_id)
);

CREATE INDEX IF NOT EXISTS idx_ratings_user    ON user_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_content ON user_ratings(content_id);

-- 평점 등록/수정 시 콘텐츠 평균 점수 업데이트 (조화평균)
CREATE OR REPLACE FUNCTION update_content_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_harmonic_mean DECIMAL(3,2);
    v_count         INT;
BEGIN
    -- 조화평균 계산: n / SUM(1/rating)
    -- 왓챠피디아 방식 - 극단값 영향 감소
    SELECT
        COUNT(*),
        CASE WHEN SUM(1.0/rating) > 0
             THEN COUNT(*) / SUM(1.0/rating)
             ELSE 0
        END
    INTO v_count, v_harmonic_mean
    FROM user_ratings
    WHERE content_id = COALESCE(NEW.content_id, OLD.content_id);

    UPDATE contents
    SET
        our_avg_rating = COALESCE(v_harmonic_mean, 0),
        total_ratings  = v_count,
        updated_at     = NOW()
    WHERE id = COALESCE(NEW.content_id, OLD.content_id);

    -- 사용자 평점 수 업데이트
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles SET total_ratings = total_ratings + 1 WHERE id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE profiles SET total_ratings = total_ratings - 1 WHERE id = OLD.user_id;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_ratings_update_content
    AFTER INSERT OR UPDATE OR DELETE ON user_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_content_rating();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 리뷰
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS user_reviews (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content_id       UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    body             TEXT NOT NULL CHECK (length(body) >= 10 AND length(body) <= 2000),
    contains_spoiler BOOLEAN DEFAULT FALSE,
    like_count       INT DEFAULT 0,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, content_id)  -- 사용자당 콘텐츠 1개 리뷰
);

CREATE INDEX IF NOT EXISTS idx_reviews_user    ON user_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_content ON user_reviews(content_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created ON user_reviews(created_at DESC);

-- 리뷰 좋아요
CREATE TABLE IF NOT EXISTS review_likes (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    review_id   UUID NOT NULL REFERENCES user_reviews(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, review_id)
);

-- 리뷰 좋아요 수 자동 업데이트
CREATE OR REPLACE FUNCTION update_review_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE user_reviews SET like_count = like_count + 1 WHERE id = NEW.review_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE user_reviews SET like_count = like_count - 1 WHERE id = OLD.review_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER review_likes_count
    AFTER INSERT OR DELETE ON review_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_review_like_count();

-- 리뷰 수 업데이트 (콘텐츠)
CREATE OR REPLACE FUNCTION update_content_review_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE contents SET our_review_count = our_review_count + 1 WHERE id = NEW.content_id;
        UPDATE profiles SET total_reviews = total_reviews + 1 WHERE id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE contents SET our_review_count = our_review_count - 1 WHERE id = OLD.content_id;
        UPDATE profiles SET total_reviews = total_reviews - 1 WHERE id = OLD.user_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_reviews_count
    AFTER INSERT OR DELETE ON user_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_content_review_count();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 사용자 컬렉션
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS collections (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title            TEXT NOT NULL CHECK (length(title) >= 2 AND length(title) <= 100),
    description      TEXT,
    cover_image_url  TEXT,
    is_public        BOOLEAN DEFAULT TRUE,
    like_count       INT DEFAULT 0,
    item_count       INT DEFAULT 0,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collections_user      ON collections(user_id);
CREATE INDEX IF NOT EXISTS idx_collections_public    ON collections(is_public, created_at DESC);

CREATE TABLE IF NOT EXISTS collection_items (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    content_id    UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    sort_order    INT DEFAULT 0,
    note          TEXT,           -- 이 콘텐츠를 컬렉션에 넣은 이유 (옵션)
    added_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(collection_id, content_id)
);

CREATE INDEX IF NOT EXISTS idx_collection_items_collection ON collection_items(collection_id);

-- 컬렉션 아이템 수 자동 업데이트
CREATE OR REPLACE FUNCTION update_collection_item_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE collections SET item_count = item_count + 1 WHERE id = NEW.collection_id;
        UPDATE profiles SET total_collections = total_collections + 1 WHERE id = (
            SELECT user_id FROM collections WHERE id = NEW.collection_id
        );
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE collections SET item_count = item_count - 1 WHERE id = OLD.collection_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER collection_items_count
    AFTER INSERT OR DELETE ON collection_items
    FOR EACH ROW
    EXECUTE FUNCTION update_collection_item_count();

-- 컬렉션 좋아요
CREATE TABLE IF NOT EXISTS collection_likes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, collection_id)
);
