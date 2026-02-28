-- ============================================================
-- Migration 006: Additional Indexes & Performance Tuning
-- ============================================================

-- 콘텐츠 검색 성능 최적화
CREATE INDEX IF NOT EXISTS idx_contents_release_date  ON contents(release_date DESC);
CREATE INDEX IF NOT EXISTS idx_contents_avg_rating    ON contents(our_avg_rating DESC);
CREATE INDEX IF NOT EXISTS idx_contents_total_ratings ON contents(total_ratings DESC);
CREATE INDEX IF NOT EXISTS idx_contents_title_en_trgm ON contents USING GIN(title_en gin_trgm_ops);

-- OTT 가용성 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_availability_flatrate  ON content_availability(platform_id, availability_type)
    WHERE availability_type = 'flatrate';

-- AI 콘텐츠 관 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_ai_contents_approved_feed ON ai_contents(engagement_score DESC, created_at DESC)
    WHERE moderation_status = 'approved' AND is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_ai_contents_user_approved ON ai_contents(user_id, created_at DESC)
    WHERE is_active = TRUE;

-- 컬렉션 공개 피드 인덱스
CREATE INDEX IF NOT EXISTS idx_collections_public_feed ON collections(like_count DESC, created_at DESC)
    WHERE is_public = TRUE;

-- 리뷰 정렬 인덱스
CREATE INDEX IF NOT EXISTS idx_reviews_helpful ON user_reviews(content_id, like_count DESC, created_at DESC);

-- 큐레이션 섹션 만료 정리용
CREATE INDEX IF NOT EXISTS idx_curation_expires ON curation_sections(expires_at)
    WHERE expires_at IS NOT NULL;
