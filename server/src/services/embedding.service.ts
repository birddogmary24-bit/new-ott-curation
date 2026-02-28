import axios from 'axios';
import {
  getContentsWithoutEmbedding,
  updateContentEmbedding,
} from './content-sync.service';
import { query } from '../db/client';

const VOYAGE_API = 'https://api.voyageai.com/v1/embeddings';
const VOYAGE_KEY = process.env.VOYAGE_API_KEY ?? '';
const VOYAGE_MODEL = 'voyage-multilingual-2';  // 한국어 지원 최적 모델

/**
 * Voyage AI로 텍스트 임베딩 생성
 * @returns 1024차원 벡터
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const response = await axios.post(
    VOYAGE_API,
    {
      model: VOYAGE_MODEL,
      input: [text],
      input_type: 'document',
    },
    {
      headers: {
        'Authorization': `Bearer ${VOYAGE_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    }
  );

  return response.data.data[0].embedding as number[];
}

/**
 * 배치 임베딩 생성 (최대 8개씩)
 */
export async function generateBatchEmbeddings(
  texts: string[]
): Promise<number[][]> {
  // Voyage API는 배치당 최대 128개 지원
  const BATCH_SIZE = 8;
  const results: number[][] = [];

  for (let i = 0; i < texts.length; i += BATCH_SIZE) {
    const batch = texts.slice(i, i + BATCH_SIZE);
    const response = await axios.post(
      VOYAGE_API,
      {
        model: VOYAGE_MODEL,
        input: batch,
        input_type: 'document',
      },
      {
        headers: {
          'Authorization': `Bearer ${VOYAGE_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    const embeddings = response.data.data
      .sort((a: { index: number }, b: { index: number }) => a.index - b.index)
      .map((d: { embedding: number[] }) => d.embedding);

    results.push(...embeddings);

    // 레이트 리밋 방지
    await new Promise((r) => setTimeout(r, 200));
  }

  return results;
}

/**
 * 콘텐츠 임베딩 텍스트 구성
 * title + overview + 장르 + 분위기 태그
 */
function buildContentEmbeddingText(content: {
  title_ko: string;
  overview_ko?: string | null;
  genres?: string[];
  mood_tags?: string[];
}): string {
  const parts = [content.title_ko];
  if (content.overview_ko) parts.push(content.overview_ko);
  if (content.genres?.length) parts.push(`장르: ${content.genres.join(', ')}`);
  if (content.mood_tags?.length) parts.push(`분위기: ${content.mood_tags.join(', ')}`);
  return parts.join('. ');
}

/**
 * 임베딩 없는 콘텐츠 배치 처리
 * Cloud Scheduler가 매일 05:00 KST에 호출
 */
export async function processPendingEmbeddings(): Promise<void> {
  console.log('🔢 콘텐츠 임베딩 생성 시작...');

  let totalProcessed = 0;
  const BATCH_SIZE = 100;

  while (true) {
    const contents = await getContentsWithoutEmbedding(BATCH_SIZE);
    if (contents.length === 0) break;

    const texts = contents.map(buildContentEmbeddingText);
    const embeddings = await generateBatchEmbeddings(texts);

    for (let i = 0; i < contents.length; i++) {
      await updateContentEmbedding(contents[i]!.id, embeddings[i]!);
    }

    totalProcessed += contents.length;
    console.log(`   ✅ ${totalProcessed}개 처리 완료`);
  }

  console.log(`✅ 임베딩 생성 완료: 총 ${totalProcessed}개`);
}

/**
 * AI 콘텐츠 관 업로드 시 임베딩 생성
 */
export async function generateAiContentEmbedding(aiContentId: string): Promise<void> {
  const rows = await query<{
    title: string;
    description?: string | null;
    tags: string[];
  }>(
    'SELECT title, description, tags FROM ai_contents WHERE id = $1',
    [aiContentId]
  );

  const content = rows[0];
  if (!content) return;

  const text = [
    content.title,
    content.description,
    content.tags?.length ? `태그: ${content.tags.join(', ')}` : '',
  ].filter(Boolean).join('. ');

  const embedding = await generateEmbedding(text);

  await query(
    'UPDATE ai_contents SET embedding = $1 WHERE id = $2',
    [`[${embedding.join(',')}]`, aiContentId]
  );
}

/**
 * 사용자 취향 임베딩 계산
 * 긍정 평점(3.5점 이상) 콘텐츠 임베딩 가중 평균
 */
export async function computeUserTasteEmbedding(userId: string): Promise<void> {
  await query('SELECT compute_user_taste_embedding($1)', [userId]);
}
