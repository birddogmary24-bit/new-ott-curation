import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import { query, queryOne, withTransaction } from '../db/client';

export const communityRoutes = Router();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 리뷰 목록
// GET /api/community/reviews/:contentId
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
communityRoutes.get('/reviews/:contentId', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { sort = 'helpful', page = '1', limit = '20' } = req.query as Record<string, string>;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const orderBy = sort === 'helpful'
      ? 'r.like_count DESC, r.created_at DESC'
      : 'r.created_at DESC';

    const reviews = await query(`
      SELECT
        r.id, r.body, r.contains_spoiler, r.like_count, r.created_at,
        ur.rating,
        p.id AS author_id, p.nickname AS author_nickname, p.avatar_url AS author_avatar
      FROM user_reviews r
      JOIN profiles p ON p.id = r.user_id
      LEFT JOIN user_ratings ur ON ur.user_id = r.user_id AND ur.content_id = r.content_id
      WHERE r.content_id = $1
      ORDER BY ${orderBy}
      LIMIT $2 OFFSET $3
    `, [req.params['contentId'], parseInt(limit), offset]);

    res.json({ data: reviews });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 리뷰 작성
// POST /api/community/reviews
communityRoutes.post('/reviews', requireAuth, async (req: Request, res: Response) => {
  try {
    const { content_id, body, contains_spoiler } = z.object({
      content_id:       z.string().uuid(),
      body:             z.string().min(10).max(2000),
      contains_spoiler: z.boolean().default(false),
    }).parse(req.body);

    const review = await queryOne(`
      INSERT INTO user_reviews (user_id, content_id, body, contains_spoiler)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id, content_id) DO UPDATE
        SET body = EXCLUDED.body,
            contains_spoiler = EXCLUDED.contains_spoiler,
            updated_at = NOW()
      RETURNING *
    `, [req.userId, content_id, body, contains_spoiler]);

    res.status(201).json({ data: review });
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
// 컬렉션
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

// 공개 컬렉션 탐색
communityRoutes.get('/collections', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { page = '1', limit = '20' } = req.query as Record<string, string>;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const collections = await query(`
      SELECT
        c.id, c.title, c.description, c.cover_image_url,
        c.like_count, c.item_count, c.created_at,
        p.id AS creator_id, p.nickname AS creator_nickname, p.avatar_url AS creator_avatar
      FROM collections c
      JOIN profiles p ON p.id = c.user_id
      WHERE c.is_public = TRUE
      ORDER BY c.like_count DESC, c.created_at DESC
      LIMIT $1 OFFSET $2
    `, [parseInt(limit), offset]);

    res.json({ data: collections });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 컬렉션 생성
communityRoutes.post('/collections', requireAuth, async (req: Request, res: Response) => {
  try {
    const { title, description, is_public } = z.object({
      title:       z.string().min(2).max(100),
      description: z.string().max(500).optional(),
      is_public:   z.boolean().default(true),
    }).parse(req.body);

    const collection = await queryOne(`
      INSERT INTO collections (user_id, title, description, is_public)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [req.userId, title, description ?? null, is_public]);

    res.status(201).json({ data: collection });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: error.errors });
    } else {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
});

// 컬렉션 상세 + 아이템
communityRoutes.get('/collections/:id', optionalAuth, async (req: Request, res: Response) => {
  try {
    const collection = await queryOne(`
      SELECT c.*, p.nickname AS creator_nickname, p.avatar_url AS creator_avatar
      FROM collections c
      JOIN profiles p ON p.id = c.user_id
      WHERE c.id = $1 AND (c.is_public = TRUE OR c.user_id = $2)
    `, [req.params['id'], req.userId ?? '00000000-0000-0000-0000-000000000000']);

    if (!collection) {
      res.status(404).json({ error: '컬렉션을 찾을 수 없습니다.' });
      return;
    }

    const items = await query(`
      SELECT
        ci.sort_order, ci.note, ci.added_at,
        c.id, c.title_ko, c.poster_url, c.content_type,
        c.our_avg_rating, c.genres
      FROM collection_items ci
      JOIN contents c ON c.id = ci.content_id
      WHERE ci.collection_id = $1
      ORDER BY ci.sort_order, ci.added_at
    `, [req.params['id']]);

    res.json({ data: { ...collection, items } });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 컬렉션에 콘텐츠 추가
communityRoutes.post('/collections/:id/items', requireAuth, async (req: Request, res: Response) => {
  try {
    const { content_id, note } = z.object({
      content_id: z.string().uuid(),
      note:       z.string().max(200).optional(),
    }).parse(req.body);

    // 내 컬렉션인지 확인
    const collection = await queryOne(
      'SELECT id FROM collections WHERE id = $1 AND user_id = $2',
      [req.params['id'], req.userId]
    );
    if (!collection) {
      res.status(403).json({ error: '권한이 없습니다.' });
      return;
    }

    await query(`
      INSERT INTO collection_items (collection_id, content_id, note, sort_order)
      VALUES ($1, $2, $3, (
        SELECT COALESCE(MAX(sort_order), 0) + 1
        FROM collection_items WHERE collection_id = $1
      ))
      ON CONFLICT (collection_id, content_id) DO NOTHING
    `, [req.params['id'], content_id, note ?? null]);

    res.json({ ok: true });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: error.errors });
    } else {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
});
