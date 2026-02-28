import { Router, Request, Response } from 'express';
import { requireInternalSecret } from '../middleware/auth.middleware';
import { syncJustWatchContent } from '../services/content-sync.service';
import { processPendingEmbeddings } from '../services/embedding.service';
import { computeNightlyCuration } from '../services/curation.service';
import { query } from '../db/client';

export const internalRoutes = Router();

// 모든 내부 라우트에 시크릿 검증 적용
internalRoutes.use(requireInternalSecret);

// POST /internal/sync/content - JustWatch + TMDb 콘텐츠 동기화
internalRoutes.post('/sync/content', async (_req: Request, res: Response) => {
  console.log('⏰ [Cloud Scheduler] 콘텐츠 동기화 시작');
  res.json({ started: true });  // 즉시 응답 (Cloud Scheduler 타임아웃 방지)

  try {
    await syncJustWatchContent();
  } catch (error) {
    console.error('❌ 콘텐츠 동기화 실패:', error);
  }
});

// POST /internal/sync/embeddings - 임베딩 배치 생성
internalRoutes.post('/sync/embeddings', async (_req: Request, res: Response) => {
  console.log('⏰ [Cloud Scheduler] 임베딩 생성 시작');
  res.json({ started: true });

  try {
    await processPendingEmbeddings();
  } catch (error) {
    console.error('❌ 임베딩 생성 실패:', error);
  }
});

// POST /internal/curation/nightly - 야간 개인화 큐레이션 사전 계산
internalRoutes.post('/curation/nightly', async (_req: Request, res: Response) => {
  console.log('⏰ [Cloud Scheduler] 야간 큐레이션 시작');
  res.json({ started: true });

  try {
    await computeNightlyCuration();
  } catch (error) {
    console.error('❌ 야간 큐레이션 실패:', error);
  }
});

// POST /internal/ai-hall/update-scores - AI Hall 피드 스코어 갱신
internalRoutes.post('/ai-hall/update-scores', async (_req: Request, res: Response) => {
  try {
    await query('SELECT refresh_all_feed_scores()');
    res.json({ ok: true, updated_at: new Date().toISOString() });
  } catch (error) {
    console.error('❌ 피드 스코어 갱신 실패:', error);
    res.status(500).json({ error: 'Failed to update scores' });
  }
});
