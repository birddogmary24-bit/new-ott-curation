import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { query, queryOne } from '../db/client';
import { optionalAuth } from '../middleware/auth.middleware';

export const contentRoutes = Router();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GET /api/contents
// 콘텐츠 목록 (필터: OTT 플랫폼, 장르, 정렬)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
const ListQuerySchema = z.object({
  platforms: z.string().optional(),    // 'netflix,tving' → 콤마 구분
  genres:    z.string().optional(),    // '드라마,스릴러'
  type:      z.enum(['movie', 'tv']).optional(),
  sort:      z.enum(['rating', 'new', 'trending']).default('rating'),
  page:      z.coerce.number().int().min(1).default(1),
  limit:     z.coerce.number().int().min(1).max(50).default(20),
});

contentRoutes.get('/', optionalAuth, async (req: Request, res: Response) => {
  try {
    const params = ListQuerySchema.parse(req.query);
    const offset = (params.page - 1) * params.limit;

    const platformIds = params.platforms?.split(',').filter(Boolean) ?? [];
    const genreList   = params.genres?.split(',').filter(Boolean) ?? [];

    let whereClause = 'WHERE 1=1';
    const values: unknown[] = [];
    let idx = 1;

    if (params.type) {
      whereClause += ` AND c.content_type = $${idx++}`;
      values.push(params.type);
    }

    if (genreList.length > 0) {
      whereClause += ` AND c.genres && $${idx++}`;
      values.push(genreList);
    }

    if (platformIds.length > 0) {
      whereClause += ` AND EXISTS (
        SELECT 1 FROM content_availability ca
        WHERE ca.content_id = c.id
          AND ca.platform_id = ANY($${idx++})
          AND ca.availability_type = 'flatrate'
      )`;
      values.push(platformIds);
    }

    const orderBy = {
      rating:   'c.our_avg_rating DESC, c.total_ratings DESC',
      new:      'c.release_date DESC NULLS LAST',
      trending: 'c.total_ratings DESC, c.our_avg_rating DESC',
    }[params.sort];

    const sql = `
      SELECT
        c.id, c.content_type, c.title_ko, c.title_en,
        c.poster_url, c.release_date, c.genres,
        c.our_avg_rating, c.total_ratings, c.our_review_count,
        c.runtime_minutes, c.episode_count,
        COALESCE(
          json_agg(DISTINCT jsonb_build_object(
            'platform_id', ca.platform_id,
            'type', ca.availability_type
          )) FILTER (WHERE ca.platform_id IS NOT NULL),
          '[]'
        ) AS platforms
      FROM contents c
      LEFT JOIN content_availability ca ON ca.content_id = c.id
        AND ca.availability_type = 'flatrate'
      ${whereClause}
      GROUP BY c.id
      ORDER BY ${orderBy}
      LIMIT $${idx++} OFFSET $${idx++}
    `;
    values.push(params.limit, offset);

    const contents = await query(sql, values);
    res.json({ data: contents, page: params.page, limit: params.limit });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: error.errors });
    } else {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GET /api/contents/search
// 한국어 퍼지 텍스트 검색 (pg_trgm)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
contentRoutes.get('/search', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { q, limit = '20' } = req.query as Record<string, string>;

    if (!q || q.trim().length < 1) {
      res.status(400).json({ error: '검색어를 입력해주세요.' });
      return;
    }

    const results = await query(`
      SELECT
        c.id, c.content_type, c.title_ko, c.title_en,
        c.poster_url, c.release_date, c.genres,
        c.our_avg_rating, c.total_ratings,
        similarity(c.title_ko, $1) AS title_sim
      FROM contents c
      WHERE
        c.title_ko % $1                    -- 퍼지 유사도
        OR c.title_en ILIKE $2             -- 영문 포함
        OR c.keywords && ARRAY[$1]         -- 키워드 매칭
        OR c.cast_names && ARRAY[$1]       -- 출연진 이름 매칭
      ORDER BY title_sim DESC, c.our_avg_rating DESC
      LIMIT $3
    `, [q.trim(), `%${q.trim()}%`, parseInt(limit)]);

    res.json({ data: results, query: q });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GET /api/contents/:id
// 콘텐츠 상세 (OTT 가용성 포함)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
contentRoutes.get('/:id', optionalAuth, async (req: Request, res: Response) => {
  try {
    const content = await queryOne(`
      SELECT
        c.*,
        COALESCE(
          json_agg(
            jsonb_build_object(
              'platform_id',       ca.platform_id,
              'platform_name_ko',  op.name_ko,
              'platform_color',    op.color_hex,
              'availability_type', ca.availability_type,
              'price',             ca.price,
              'quality',           ca.quality,
              'deep_link_url',     ca.deep_link_url
            ) ORDER BY op.sort_order
          ) FILTER (WHERE ca.platform_id IS NOT NULL),
          '[]'
        ) AS availability
      FROM contents c
      LEFT JOIN content_availability ca ON ca.content_id = c.id
      LEFT JOIN ott_platforms op ON op.id = ca.platform_id
      WHERE c.id = $1
      GROUP BY c.id
    `, [req.params['id']]);

    if (!content) {
      res.status(404).json({ error: '콘텐츠를 찾을 수 없습니다.' });
      return;
    }

    // 유사 콘텐츠 (벡터 유사도 상위 5개)
    const similar = await query(`
      SELECT id, title_ko, poster_url, our_avg_rating, content_type
      FROM contents
      WHERE id != $1 AND embedding IS NOT NULL
      ORDER BY embedding <=> (SELECT embedding FROM contents WHERE id = $1)
      LIMIT 5
    `, [req.params['id']]);

    // 사용자 평점 (로그인 시)
    let userRating = null;
    if (req.userId) {
      userRating = await queryOne<{ rating: number }>(
        'SELECT rating FROM user_ratings WHERE user_id = $1 AND content_id = $2',
        [req.userId, req.params['id']]
      );
    }

    res.json({
      data: content,
      similar,
      user_rating: userRating?.rating ?? null,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});
