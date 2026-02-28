import { Router, Request, Response } from 'express';
import { z } from 'zod';
import axios from 'axios';
import { requireAuth } from '../middleware/auth.middleware';
import { createCustomTokenForKakao } from '../utils/firebase';
import { query, queryOne, withTransaction } from '../db/client';
import { computeUserTasteEmbedding } from '../services/embedding.service';

export const userRoutes = Router();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 카카오 로그인 커스텀 토큰 발급
// POST /api/users/auth/kakao
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
userRoutes.post('/auth/kakao', async (req: Request, res: Response) => {
  try {
    const { kakao_access_token } = z.object({
      kakao_access_token: z.string().min(1),
    }).parse(req.body);

    // 카카오 API로 사용자 정보 검증
    const kakaoUserResp = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: { Authorization: `Bearer ${kakao_access_token}` },
      timeout: 5000,
    });

    const kakaoUser = kakaoUserResp.data;
    const email = kakaoUser?.kakao_account?.email as string | undefined;

    // Firebase 커스텀 토큰 발급
    const customToken = await createCustomTokenForKakao(String(kakaoUser.id), email);

    res.json({ custom_token: customToken });
  } catch (error) {
    console.error(error);
    res.status(401).json({ error: '카카오 토큰 검증 실패' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 프로필 조회
// GET /api/users/profile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
userRoutes.get('/profile', requireAuth, async (req: Request, res: Response) => {
  try {
    let profile = await queryOne(`
      SELECT p.*, ute.rated_count AS taste_calibrated_count
      FROM profiles p
      LEFT JOIN user_taste_embeddings ute ON ute.user_id = p.id
      WHERE p.firebase_uid = $1
    `, [req.uid]);

    // 프로필이 없으면 첫 로그인 → 자동 생성
    if (!profile) {
      const nickname = req.firebaseUser?.name ?? `user_${Date.now()}`;
      const avatar = req.firebaseUser?.picture ?? null;

      profile = await queryOne(`
        INSERT INTO profiles (firebase_uid, nickname, avatar_url)
        VALUES ($1, $2, $3)
        RETURNING *
      `, [req.uid, nickname, avatar]);
    }

    res.json({ data: profile });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 프로필 수정
// PUT /api/users/profile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
const UpdateProfileSchema = z.object({
  nickname:           z.string().min(2).max(20).optional(),
  bio:                z.string().max(200).optional(),
  preferred_genres:   z.array(z.string()).optional(),
  preferred_platforms:z.array(z.string()).optional(),
  taste_keywords:     z.array(z.string()).optional(),
});

userRoutes.put('/profile', requireAuth, async (req: Request, res: Response) => {
  try {
    const updates = UpdateProfileSchema.parse(req.body);
    const fields = Object.entries(updates)
      .filter(([, v]) => v !== undefined)
      .map(([k], i) => `${k} = $${i + 2}`)
      .join(', ');

    if (!fields) { res.json({ ok: true }); return; }

    const values = Object.values(updates).filter((v) => v !== undefined);

    await query(
      `UPDATE profiles SET ${fields}, updated_at = NOW() WHERE firebase_uid = $1`,
      [req.uid, ...values]
    );

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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 온보딩 완료
// POST /api/users/onboarding
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
const OnboardingSchema = z.object({
  preferred_genres:    z.array(z.string()).min(1),
  preferred_platforms: z.array(z.string()).min(1),
  initial_ratings:     z.array(z.object({
    content_id: z.string().uuid(),
    rating:     z.number().min(0.5).max(5),
  })).optional().default([]),
});

userRoutes.post('/onboarding', requireAuth, async (req: Request, res: Response) => {
  try {
    const { preferred_genres, preferred_platforms, initial_ratings } = OnboardingSchema.parse(req.body);

    await withTransaction(async (client) => {
      // 취향 설정 저장
      await client.query(`
        UPDATE profiles SET
          preferred_genres    = $1,
          preferred_platforms = $2,
          onboarding_completed = TRUE,
          updated_at = NOW()
        WHERE firebase_uid = $3
      `, [preferred_genres, preferred_platforms, req.uid]);

      // 초기 평점 저장
      for (const r of initial_ratings) {
        await client.query(`
          INSERT INTO user_ratings (user_id, content_id, rating)
          VALUES ($1, $2, $3)
          ON CONFLICT (user_id, content_id) DO UPDATE SET rating = EXCLUDED.rating
        `, [req.userId, r.content_id, r.rating]);
      }
    });

    // 취향 임베딩 비동기 계산 (응답 후)
    if (req.userId && initial_ratings.length > 0) {
      computeUserTasteEmbedding(req.userId).catch(console.error);
    }

    res.json({ ok: true, onboarding_completed: true });
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
// 내 평점 목록
// GET /api/users/ratings
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
userRoutes.get('/ratings', requireAuth, async (req: Request, res: Response) => {
  try {
    const { page = '1', limit = '30' } = req.query as Record<string, string>;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const ratings = await query(`
      SELECT
        ur.rating, ur.created_at,
        c.id, c.title_ko, c.poster_url, c.content_type, c.our_avg_rating
      FROM user_ratings ur
      JOIN contents c ON c.id = ur.content_id
      WHERE ur.user_id = $1
      ORDER BY ur.created_at DESC
      LIMIT $2 OFFSET $3
    `, [req.userId, parseInt(limit), offset]);

    res.json({ data: ratings });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 평점 등록/수정
// POST /api/users/ratings
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
userRoutes.post('/ratings', requireAuth, async (req: Request, res: Response) => {
  try {
    const { content_id, rating } = z.object({
      content_id: z.string().uuid(),
      rating:     z.number().min(0.5).max(5).multipleOf(0.5),
    }).parse(req.body);

    await query(`
      INSERT INTO user_ratings (user_id, content_id, rating)
      VALUES ($1, $2, $3)
      ON CONFLICT (user_id, content_id) DO UPDATE
        SET rating = EXCLUDED.rating, updated_at = NOW()
    `, [req.userId, content_id, rating]);

    // 취향 임베딩 비동기 갱신
    if (req.userId) {
      computeUserTasteEmbedding(req.userId).catch(console.error);
    }

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
