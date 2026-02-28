import Anthropic from '@anthropic-ai/sdk';
import { query, queryOne } from '../db/client';
import { generateEmbedding } from './embedding.service';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

interface CurationResult {
  contents: ContentSummary[];
  ai_reason: string;
  section_title: string;
}

interface ContentSummary {
  id: string;
  title_ko: string;
  poster_url: string | null;
  our_avg_rating: number;
  content_type: string;
  genres: string[];
}

/**
 * 자연어 큐레이션 요청 처리
 * 예: "비오는 날 혼자 볼 영화 추천해줘"
 */
export async function processNaturalLanguageCuration(
  prompt: string,
  userId: string | undefined,
  platformIds: string[]
): Promise<CurationResult> {
  // 1. Claude로 프롬프트 분석
  const intentResponse = await anthropic.messages.create({
    model: 'claude-haiku-4-5',
    max_tokens: 500,
    messages: [{
      role: 'user',
      content: `다음 한국어 콘텐츠 추천 요청을 분석해서 JSON으로 반환해주세요.
요청: "${prompt}"

반환 형식:
{
  "search_text": "임베딩 검색에 사용할 한국어 텍스트 (장르, 분위기, 맥락 포함)",
  "content_type": "movie" | "tv" | null,
  "genres": ["장르명"],
  "mood": "분위기 설명",
  "section_title": "큐레이션 섹션 제목 (20자 이내)"
}`,
    }],
  });

  let intent = {
    search_text: prompt,
    content_type: null as string | null,
    genres: [] as string[],
    mood: '',
    section_title: '맞춤 추천',
  };

  try {
    const jsonMatch = (intentResponse.content[0] as { type: string; text: string }).text.match(/\{[\s\S]*\}/);
    if (jsonMatch) intent = { ...intent, ...JSON.parse(jsonMatch[0]) };
  } catch {
    // JSON 파싱 실패 시 원본 텍스트 사용
  }

  // 2. 검색 텍스트로 임베딩 생성
  const searchEmbedding = await generateEmbedding(intent.search_text);

  // 3. pgvector로 유사 콘텐츠 검색
  const values: unknown[] = [`[${searchEmbedding.join(',')}]`];
  let idx = 2;
  let whereClause = 'WHERE c.embedding IS NOT NULL';

  if (intent.content_type) {
    whereClause += ` AND c.content_type = $${idx++}`;
    values.push(intent.content_type);
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

  // 이미 평가한 콘텐츠 제외
  if (userId) {
    whereClause += ` AND c.id NOT IN (
      SELECT content_id FROM user_ratings WHERE user_id = $${idx++}
    )`;
    values.push(userId);
  }

  values.push(20); // LIMIT

  const contents = await query<ContentSummary>(`
    SELECT
      c.id, c.title_ko, c.poster_url,
      c.our_avg_rating, c.content_type, c.genres,
      1 - (c.embedding <=> $1::vector) AS similarity
    FROM contents c
    ${whereClause}
    ORDER BY c.embedding <=> $1::vector
    LIMIT $${idx}
  `, values);

  // 4. Claude로 큐레이션 이유 생성
  let aiReason = `"${prompt}"에 딱 맞는 콘텐츠를 찾았어요.`;

  if (contents.length > 0) {
    const titlesText = contents.slice(0, 3).map((c) => c.title_ko).join(', ');

    const reasonResponse = await anthropic.messages.create({
      model: 'claude-haiku-4-5',
      max_tokens: 150,
      messages: [{
        role: 'user',
        content: `사용자가 "${prompt}"를 원합니다.
추천한 콘텐츠: ${titlesText}

이 추천에 대한 간단한 이유를 1-2문장의 친근한 한국어로 작성해주세요. 50자 이내.`,
      }],
    });

    aiReason = (reasonResponse.content[0] as { type: string; text: string }).text.trim();
  }

  return {
    contents,
    ai_reason: aiReason,
    section_title: intent.section_title,
  };
}

/**
 * 야간 배치: 활성 사용자 개인화 큐레이션 사전 계산
 * Cloud Scheduler가 매일 03:00 KST에 호출
 */
export async function computeNightlyCuration(): Promise<void> {
  console.log('🌙 야간 큐레이션 사전 계산 시작...');

  // 최근 7일 내 활성 사용자
  const activeUsers = await query<{ id: string; preferred_platforms: string[] }>(`
    SELECT DISTINCT p.id, p.preferred_platforms
    FROM profiles p
    JOIN user_ratings ur ON ur.user_id = p.id
    WHERE ur.created_at > NOW() - INTERVAL '7 days'
      AND p.onboarding_completed = TRUE
    LIMIT 1000
  `);

  console.log(`   👤 활성 사용자 ${activeUsers.length}명 처리`);

  let processed = 0;
  for (const user of activeUsers) {
    try {
      await computePersonalizedSectionsForUser(user.id, user.preferred_platforms ?? []);
      processed++;
    } catch (err) {
      console.error(`   ⚠️  사용자 ${user.id} 큐레이션 실패:`, err);
    }
  }

  // 전체 사용자용 트렌딩/장르별 섹션도 갱신
  await computeGlobalSections();

  console.log(`✅ 야간 큐레이션 완료: ${processed}명 처리`);
}

/**
 * 특정 사용자 개인화 섹션 생성
 */
async function computePersonalizedSectionsForUser(
  userId: string,
  platformIds: string[]
): Promise<void> {
  // 개인화 추천 (pgvector)
  const personalizedContents = await query<{ content_id: string }>(`
    SELECT content_id
    FROM get_personalized_content($1, $2, NULL, 20)
  `, [userId, platformIds.length > 0 ? platformIds : null]);

  if (personalizedContents.length === 0) return;

  const contentIds = personalizedContents.map((c) => c.content_id);

  // Claude로 섹션 제목 생성
  const titleResponse = await anthropic.messages.create({
    model: 'claude-haiku-4-5',
    max_tokens: 50,
    messages: [{
      role: 'user',
      content: '개인화 콘텐츠 추천 섹션의 제목을 한국어로 15자 이내로 만들어주세요. 예: "당신을 위한 오늘의 선택"',
    }],
  });
  const sectionTitle = (titleResponse.content[0] as { text: string }).text.trim();

  // 기존 개인화 섹션 만료 처리
  await query(`
    UPDATE curation_sections
    SET is_active = FALSE, expires_at = NOW()
    WHERE target_user_id = $1 AND section_type = 'personalized'
  `, [userId]);

  // 새 섹션 저장
  await query(`
    INSERT INTO curation_sections (
      section_type, title_ko, ai_reason,
      target_user_id, content_ids, expires_at
    ) VALUES (
      'personalized', $1, $2, $3, $4,
      NOW() + INTERVAL '24 hours'
    )
  `, [
    sectionTitle,
    '취향 분석을 바탕으로 골랐어요',
    userId,
    contentIds,
  ]);
}

/**
 * 전체 사용자 공통 섹션 (트렌딩, 장르별, 신규)
 */
async function computeGlobalSections(): Promise<void> {
  // 기존 전체 섹션 만료
  await query(`
    UPDATE curation_sections
    SET is_active = FALSE
    WHERE target_user_id IS NULL
      AND section_type IN ('trending', 'new_arrivals', 'by_genre')
  `);

  // 트렌딩 섹션
  const trending = await query<{ id: string }>(`
    SELECT id FROM contents
    ORDER BY total_ratings DESC, our_avg_rating DESC
    LIMIT 20
  `);

  await query(`
    INSERT INTO curation_sections (
      section_type, title_ko, content_ids, layout_type, sort_order
    ) VALUES ('trending', '지금 가장 많이 보는', $1, 'hero', 0)
  `, [trending.map((c) => c.id)]);

  // 신규 콘텐츠
  const newContent = await query<{ id: string }>(`
    SELECT id FROM contents
    WHERE release_date > NOW() - INTERVAL '30 days'
    ORDER BY release_date DESC
    LIMIT 20
  `);

  if (newContent.length > 0) {
    await query(`
      INSERT INTO curation_sections (
        section_type, title_ko, content_ids, sort_order
      ) VALUES ('new_arrivals', '이번 달 새로 들어온', $1, 1)
    `, [newContent.map((c) => c.id)]);
  }

  // 인기 장르별 섹션
  const popularGenres = ['드라마', '스릴러', '로맨스', '코미디', '액션'];
  for (let i = 0; i < popularGenres.length; i++) {
    const genre = popularGenres[i]!;
    const genreContent = await query<{ id: string }>(`
      SELECT id FROM contents
      WHERE genres @> ARRAY[$1]
      ORDER BY our_avg_rating DESC, total_ratings DESC
      LIMIT 15
    `, [genre]);

    if (genreContent.length > 0) {
      await query(`
        INSERT INTO curation_sections (
          section_type, title_ko, genre_filter, content_ids, sort_order
        ) VALUES ('by_genre', $1, $2, $3, $4)
      `, [`인기 ${genre}`, genre, genreContent.map((c) => c.id), i + 2]);
    }
  }
}

/**
 * 홈 화면 큐레이션 섹션 조회
 */
export async function getHomeSections(userId: string | undefined) {
  // 개인화 섹션 (로그인 사용자)
  const personalizedSections = userId
    ? await query(`
        SELECT * FROM curation_sections
        WHERE target_user_id = $1
          AND is_active = TRUE
          AND (expires_at IS NULL OR expires_at > NOW())
        ORDER BY sort_order
        LIMIT 3
      `, [userId])
    : [];

  // 전체 공통 섹션
  const globalSections = await query(`
    SELECT * FROM curation_sections
    WHERE target_user_id IS NULL
      AND is_active = TRUE
      AND (expires_at IS NULL OR expires_at > NOW())
    ORDER BY sort_order
    LIMIT 10
  `);

  // 섹션의 content_ids를 실제 콘텐츠로 채우기
  const allSections = [...personalizedSections, ...globalSections];

  const enrichedSections = await Promise.all(
    allSections.map(async (section: { content_ids: string[]; [key: string]: unknown }) => {
      if (!section.content_ids?.length) return section;

      // content_ids 순서 유지하면서 조회
      const contents = await query<ContentSummary>(`
        SELECT c.id, c.title_ko, c.poster_url, c.our_avg_rating, c.content_type, c.genres
        FROM contents c
        WHERE c.id = ANY($1)
        ORDER BY array_position($1, c.id)
      `, [section.content_ids]);

      return { ...section, contents };
    })
  );

  return enrichedSections;
}
