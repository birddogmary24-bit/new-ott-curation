import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import {
  processNaturalLanguageCuration,
  getHomeSections,
} from '../services/curation.service';
import { query } from '../db/client';

export const curationRoutes = Router();

// GET /api/curations/home - 홈 화면 큐레이션 섹션
curationRoutes.get('/home', optionalAuth, async (req: Request, res: Response) => {
  try {
    const sections = await getHomeSections(req.userId);
    res.json({ data: sections });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /api/curations/chat - AI 자연어 큐레이션
const ChatSchema = z.object({
  prompt:     z.string().min(2).max(200),
  platforms:  z.array(z.string()).optional().default([]),
});

curationRoutes.post('/chat', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { prompt, platforms } = ChatSchema.parse(req.body);
    const result = await processNaturalLanguageCuration(prompt, req.userId, platforms);
    res.json({ data: result });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: error.errors });
    } else {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
});

// GET /api/curations/taste-profile - 취향 프로필
curationRoutes.get('/taste-profile', requireAuth, async (req: Request, res: Response) => {
  try {
    // 장르 분포 (평점 기반)
    const genreDistribution = await query(`
      SELECT
        unnest(c.genres) AS genre,
        COUNT(*) AS count,
        AVG(ur.rating) AS avg_rating
      FROM user_ratings ur
      JOIN contents c ON c.id = ur.content_id
      WHERE ur.user_id = $1
      GROUP BY genre
      ORDER BY count DESC
      LIMIT 10
    `, [req.userId]);

    // 플랫폼 분포
    const platformDistribution = await query(`
      SELECT
        ca.platform_id,
        op.name_ko,
        COUNT(*) AS watched_count
      FROM user_ratings ur
      JOIN contents c ON c.id = ur.content_id
      JOIN content_availability ca ON ca.content_id = c.id AND ca.availability_type = 'flatrate'
      JOIN ott_platforms op ON op.id = ca.platform_id
      WHERE ur.user_id = $1
      GROUP BY ca.platform_id, op.name_ko
      ORDER BY watched_count DESC
    `, [req.userId]);

    // 평점 통계
    const ratingStats = await query(`
      SELECT
        COUNT(*) AS total,
        AVG(rating) AS avg_rating,
        MIN(rating) AS min_rating,
        MAX(rating) AS max_rating
      FROM user_ratings
      WHERE user_id = $1
    `, [req.userId]);

    res.json({
      data: {
        genre_distribution: genreDistribution,
        platform_distribution: platformDistribution,
        rating_stats: ratingStats[0],
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /api/curations/interaction - 큐레이션 상호작용 로그
const InteractionSchema = z.object({
  curation_section_id: z.string().uuid(),
  content_id:          z.string().uuid(),
  interaction_type:    z.enum(['impression', 'click', 'dismiss', 'save', 'rate']),
});

curationRoutes.post('/interaction', requireAuth, async (req: Request, res: Response) => {
  try {
    const body = InteractionSchema.parse(req.body);
    await query(`
      INSERT INTO curation_interactions
        (user_id, curation_section_id, content_id, interaction_type)
      VALUES ($1, $2, $3, $4)
    `, [req.userId, body.curation_section_id, body.content_id, body.interaction_type]);
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
