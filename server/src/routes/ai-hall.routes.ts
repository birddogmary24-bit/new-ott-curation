import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { Storage } from '@google-cloud/storage';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import { query, queryOne } from '../db/client';
import { generateAiContentEmbedding } from '../services/embedding.service';
import Anthropic from '@anthropic-ai/sdk';

export const aiHallRoutes = Router();

const storage = new Storage();
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const VIDEO_BUCKET = process.env.GCS_VIDEO_BUCKET ?? 'ott-curation-ai-videos';
const THUMBNAIL_BUCKET = process.env.GCS_THUMBNAIL_BUCKET ?? 'ott-curation-thumbnails';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GET /api/ai-hall/feed - AI 콘텐츠 피드
// 개인화 + 참여도 + 신선도 기반
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
aiHallRoutes.get('/feed', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { cursor, limit = '20' } = req.query as Record<string, string>;
    const pageLimit = Math.min(parseInt(limit), 50);

    let feedQuery = `
      SELECT
        ac.id, ac.title, ac.description, ac.content_type,
        ac.thumbnail_url, ac.duration_seconds,
        ac.view_count, ac.like_count, ac.comment_count,
        ac.ai_tool_used, ac.tags, ac.created_at,
        ac.engagement_score,
        p.id AS creator_id, p.nickname AS creator_nickname, p.avatar_url AS creator_avatar
    `;

    // 로그인 사용자: 좋아요 여부 + 개인화 스코어 포함
    if (req.userId) {
      feedQuery += `,
        EXISTS(
          SELECT 1 FROM ai_content_likes
          WHERE user_id = $2 AND ai_content_id = ac.id
        ) AS is_liked,
        CASE WHEN ute.taste_embedding IS NOT NULL
          THEN (1 - (ac.embedding <=> ute.taste_embedding)) * 0.2
          ELSE 0
        END AS personalization_boost
      `;
    } else {
      feedQuery += `, FALSE AS is_liked, 0 AS personalization_boost`;
    }

    feedQuery += `
      FROM ai_contents ac
      JOIN profiles p ON p.id = ac.user_id
    `;

    if (req.userId) {
      feedQuery += `
        LEFT JOIN user_taste_embeddings ute ON ute.user_id = $2
      `;
    }

    feedQuery += `
      WHERE ac.moderation_status = 'approved'
        AND ac.is_active = TRUE
    `;

    const values: unknown[] = [];
    let idx = 1;

    if (cursor) {
      feedQuery += ` AND ac.created_at < $${idx++}`;
      values.push(new Date(cursor));
    }

    if (req.userId) {
      values.push(req.userId);  // $2 for is_liked and personalization
    }

    feedQuery += `
      ORDER BY (ac.engagement_score + personalization_boost) DESC, ac.created_at DESC
      LIMIT $${idx}
    `;
    values.push(pageLimit);

    const feed = await query(feedQuery, values);
    const nextCursor = feed.length === pageLimit
      ? (feed[feed.length - 1] as { created_at: string })?.created_at
      : null;

    res.json({ data: feed, next_cursor: nextCursor });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// POST /api/ai-hall/upload - 업로드용 Signed URL 발급
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
const UploadSchema = z.object({
  title:           z.string().min(2).max(100),
  description:     z.string().max(500).optional(),
  content_type:    z.enum(['short_video', 'clip', 'trailer_remix', 'highlight', 'fan_edit']),
  related_content_id: z.string().uuid().optional(),
  ai_tool_used:    z.string().max(50).optional(),
  tags:            z.array(z.string()).max(10).optional().default([]),
  duration_seconds:z.number().int().min(1).max(60),
  file_size_bytes: z.number().int().positive(),
  filename:        z.string(),
});

aiHallRoutes.post('/upload', requireAuth, async (req: Request, res: Response) => {
  try {
    const body = UploadSchema.parse(req.body);

    // AI 콘텐츠 레코드 생성 (pending 상태)
    const result = await query<{ id: string }>(`
      INSERT INTO ai_contents (
        user_id, title, description, content_type,
        related_content_id, ai_tool_used, tags,
        duration_seconds, file_size_bytes,
        video_url, moderation_status
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending','pending')
      RETURNING id
    `, [
      req.userId, body.title, body.description ?? null, body.content_type,
      body.related_content_id ?? null, body.ai_tool_used ?? null,
      body.tags, body.duration_seconds, body.file_size_bytes,
    ]);

    const contentId = result[0]!.id;
    const extension = body.filename.split('.').pop() ?? 'mp4';

    // Cloud Storage Signed URL 발급 (영상 + 썸네일)
    const videoPath = `${req.userId}/${contentId}.${extension}`;
    const thumbPath = `${req.userId}/${contentId}.jpg`;

    const [videoSignedUrl] = await storage
      .bucket(VIDEO_BUCKET)
      .file(videoPath)
      .getSignedUrl({
        version: 'v4',
        action: 'write',
        expires: Date.now() + 30 * 60 * 1000,  // 30분
        contentType: `video/${extension}`,
      });

    const [thumbSignedUrl] = await storage
      .bucket(THUMBNAIL_BUCKET)
      .file(thumbPath)
      .getSignedUrl({
        version: 'v4',
        action: 'write',
        expires: Date.now() + 30 * 60 * 1000,
        contentType: 'image/jpeg',
      });

    res.json({
      content_id:    contentId,
      video_upload_url:     videoSignedUrl,
      thumbnail_upload_url: thumbSignedUrl,
    });
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
// POST /api/ai-hall/:id/upload-complete - 업로드 완료 후 URL 업데이트 + 모더레이션
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
aiHallRoutes.post('/:id/upload-complete', requireAuth, async (req: Request, res: Response) => {
  try {
    const contentId = req.params['id']!;
    const { video_path, thumbnail_path } = z.object({
      video_path:     z.string(),
      thumbnail_path: z.string().optional(),
    }).parse(req.body);

    const videoPublicUrl = `gs://${VIDEO_BUCKET}/${video_path}`;
    const thumbPublicUrl = thumbnail_path
      ? `https://storage.googleapis.com/${THUMBNAIL_BUCKET}/${thumbnail_path}`
      : null;

    await query(`
      UPDATE ai_contents
      SET video_url = $1, thumbnail_url = $2
      WHERE id = $3 AND user_id = $4
    `, [videoPublicUrl, thumbPublicUrl, contentId, req.userId]);

    res.json({ ok: true, message: '업로드 완료. 검토 후 게시됩니다.' });

    // 비동기: 모더레이션 + 임베딩 생성
    moderateAndActivate(contentId, thumbPublicUrl).catch(console.error);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * Claude Vision으로 콘텐츠 모더레이션 후 승인/거절
 */
async function moderateAndActivate(contentId: string, thumbnailUrl: string | null): Promise<void> {
  try {
    let moderationStatus = 'approved';
    let moderationReason = null;

    if (thumbnailUrl) {
      const response = await anthropic.messages.create({
        model: 'claude-haiku-4-5',
        max_tokens: 200,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'url', url: thumbnailUrl },
            },
            {
              type: 'text',
              text: `이 이미지가 커뮤니티 가이드라인을 위반하는지 판단해주세요.
판단 기준: 성적 콘텐츠, 폭력, 혐오, 개인정보 노출
응답 형식 (JSON만): {"safe": true/false, "reason": "이유 (안전하면 null)"}`,
            },
          ],
        }],
      });

      try {
        const text = (response.content[0] as { text: string }).text;
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const result = JSON.parse(jsonMatch[0]);
          if (!result.safe) {
            moderationStatus = 'rejected';
            moderationReason = result.reason;
          }
        }
      } catch {
        // JSON 파싱 실패 → 안전으로 처리
      }
    }

    await query(`
      UPDATE ai_contents
      SET
        moderation_status = $1,
        moderation_reason = $2,
        moderated_at = NOW()
      WHERE id = $3
    `, [moderationStatus, moderationReason, contentId]);

    // 승인된 경우 임베딩 생성
    if (moderationStatus === 'approved') {
      await generateAiContentEmbedding(contentId);
    }
  } catch (error) {
    console.error('모더레이션 실패:', error);
    // 모더레이션 실패 시 pending 유지 (수동 검토)
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// POST /api/ai-hall/:id/like - 좋아요 토글
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
aiHallRoutes.post('/:id/like', requireAuth, async (req: Request, res: Response) => {
  try {
    const contentId = req.params['id']!;
    const existing = await queryOne(
      'SELECT id FROM ai_content_likes WHERE user_id = $1 AND ai_content_id = $2',
      [req.userId, contentId]
    );

    if (existing) {
      await query('DELETE FROM ai_content_likes WHERE user_id = $1 AND ai_content_id = $2',
        [req.userId, contentId]);
      res.json({ liked: false });
    } else {
      await query('INSERT INTO ai_content_likes (user_id, ai_content_id) VALUES ($1, $2)',
        [req.userId, contentId]);
      res.json({ liked: true });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GET /api/ai-hall/:id/comments - 댓글 목록
// POST /api/ai-hall/:id/comments - 댓글 작성
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
aiHallRoutes.get('/:id/comments', optionalAuth, async (req: Request, res: Response) => {
  try {
    const comments = await query(`
      SELECT
        c.id, c.body, c.like_count, c.created_at, c.parent_id,
        p.id AS author_id, p.nickname AS author_nickname, p.avatar_url AS author_avatar
      FROM ai_content_comments c
      JOIN profiles p ON p.id = c.user_id
      WHERE c.ai_content_id = $1 AND c.parent_id IS NULL
      ORDER BY c.created_at DESC
      LIMIT 50
    `, [req.params['id']]);
    res.json({ data: comments });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

aiHallRoutes.post('/:id/comments', requireAuth, async (req: Request, res: Response) => {
  try {
    const { body, parent_id } = z.object({
      body:      z.string().min(1).max(500),
      parent_id: z.string().uuid().optional(),
    }).parse(req.body);

    const comment = await queryOne(`
      INSERT INTO ai_content_comments
        (user_id, ai_content_id, body, parent_id)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [req.userId, req.params['id'], body, parent_id ?? null]);

    res.status(201).json({ data: comment });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: error.errors });
    } else {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
});
