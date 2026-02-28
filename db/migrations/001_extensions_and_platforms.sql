-- ============================================================
-- Migration 001: Extensions & OTT Platforms
-- ============================================================

-- pgvector: AI 임베딩 저장 및 코사인 유사도 검색
CREATE EXTENSION IF NOT EXISTS "vector";

-- pg_trgm: 한국어 퍼지 텍스트 검색
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- uuid 생성
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- OTT 플랫폼 마스터 테이블
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ott_platforms (
    id                TEXT PRIMARY KEY,          -- 'netflix', 'tving', 'coupang_play', 'watcha', 'wavve'
    name_ko           TEXT NOT NULL,             -- '넷플릭스'
    name_en           TEXT NOT NULL,             -- 'Netflix'
    logo_url          TEXT,
    color_hex         TEXT,                      -- 브랜드 컬러 (예: '#E50914')
    deep_link_scheme  TEXT,                      -- 앱 딥링크 스킴
    justwatch_id      INT,                       -- JustWatch 내부 Provider ID
    is_active         BOOLEAN DEFAULT TRUE,
    sort_order        INT DEFAULT 0,
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- 초기 OTT 플랫폼 데이터
INSERT INTO ott_platforms (id, name_ko, name_en, color_hex, deep_link_scheme, justwatch_id, sort_order)
VALUES
    ('netflix',      '넷플릭스',   'Netflix',       '#E50914', 'nflx://',         8,   1),
    ('tving',        '티빙',       'Tving',         '#FF153C', 'tving://',         234, 2),
    ('coupang_play', '쿠팡플레이', 'Coupang Play',  '#C00C3F', 'coupangplay://',   337, 3),
    ('wavve',        '웨이브',     'Wavve',         '#1155CC', 'wavve://',         356, 4),
    ('watcha',       '왓챠',       'Watcha',        '#FF0558', 'watcha://',        100, 5)
ON CONFLICT (id) DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 장르 마스터 테이블
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS genres (
    id          SERIAL PRIMARY KEY,
    name_ko     TEXT NOT NULL UNIQUE,
    name_en     TEXT NOT NULL UNIQUE,
    tmdb_id     INT,                             -- TMDb 장르 ID (매핑용)
    emoji       TEXT,
    sort_order  INT DEFAULT 0
);

INSERT INTO genres (name_ko, name_en, tmdb_id, emoji, sort_order) VALUES
    ('액션',     'Action',      28,  '💥', 1),
    ('모험',     'Adventure',   12,  '🗺️', 2),
    ('애니메이션','Animation',  16,  '🎨', 3),
    ('코미디',   'Comedy',      35,  '😂', 4),
    ('범죄',     'Crime',       80,  '🔍', 5),
    ('다큐멘터리','Documentary', 99,  '📽️', 6),
    ('드라마',   'Drama',       18,  '🎭', 7),
    ('가족',     'Family',      10751,'👨‍👩‍👧‍👦',8),
    ('판타지',   'Fantasy',     14,  '🧙', 9),
    ('공포',     'Horror',      27,  '👻', 10),
    ('음악',     'Music',       10402,'🎵',11),
    ('미스터리', 'Mystery',     9648, '🔮',12),
    ('로맨스',   'Romance',     10749,'❤️',13),
    ('SF',       'Science Fiction',878,'🚀',14),
    ('스릴러',   'Thriller',    53,  '😱',15),
    ('전쟁',     'War',         10752,'⚔️',16),
    ('서부',     'Western',     37,  '🤠',17)
ON CONFLICT (name_ko) DO NOTHING;
