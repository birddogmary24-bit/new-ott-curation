import axios from 'axios';
import { query, withTransaction } from '../db/client';

const TMDB_BASE_URL = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/w500';
const TMDB_KEY = process.env.TMDB_API_KEY ?? '';

// JustWatch 비공식 GraphQL API (공식 파트너 API 전까지 사용)
const JUSTWATCH_API = 'https://apis.justwatch.com/graphql';

// 한국 OTT 플랫폼의 JustWatch Provider ID
const KOREAN_OTT_PROVIDERS: Record<string, number> = {
  netflix:      8,
  tving:        234,
  coupang_play: 337,
  wavve:        356,
  watcha:       100,
};

interface JustWatchContent {
  id: string;
  objectType: string;
  content: {
    title: string;
    originalTitle: string;
    externalIds?: { tmdbId?: number };
    genres?: { technicalName: string }[];
    releaseYear?: number;
  };
  offers?: {
    standardWebURL?: string;
    monetizationType: string;
    retailPrice?: number;
    package: { packageId: number; technicalName: string };
  }[];
}

interface TmdbMovie {
  id: number;
  title?: string;
  name?: string;
  original_title?: string;
  overview?: string;
  poster_path?: string;
  backdrop_path?: string;
  release_date?: string;
  first_air_date?: string;
  runtime?: number;
  episode_run_time?: number[];
  number_of_episodes?: number;
  number_of_seasons?: number;
  vote_average?: number;
  genres?: { id: number; name: string }[];
  credits?: {
    cast?: { name: string; order: number }[];
    crew?: { name: string; job: string }[];
  };
}

/**
 * JustWatch에서 한국 OTT 가용성 데이터 수집
 */
export async function syncJustWatchContent(): Promise<void> {
  console.log('🔄 JustWatch 콘텐츠 동기화 시작...');

  const providerIds = Object.values(KOREAN_OTT_PROVIDERS);

  // JustWatch GraphQL 쿼리
  const graphqlQuery = `
    query GetPopularTitles($country: Country!, $providers: [ID!]) {
      popularTitles(
        country: $country
        first: 500
        filter: { packages: $providers }
      ) {
        edges {
          node {
            id
            objectType
            content(country: $country, language: "ko") {
              title
              originalTitle
              externalIds { tmdbId }
              genres { technicalName }
              releaseYear
            }
            offers(country: $country, platform: WEB) {
              standardWebURL
              monetizationType
              retailPrice
              package { packageId technicalName }
            }
          }
        }
      }
    }
  `;

  try {
    const response = await axios.post(
      JUSTWATCH_API,
      {
        query: graphqlQuery,
        variables: { country: 'KR', providers: providerIds.map(String) },
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'OTT-Curation-App/1.0',
        },
        timeout: 30000,
      }
    );

    const contents: JustWatchContent[] = response.data?.data?.popularTitles?.edges
      ?.map((e: { node: JustWatchContent }) => e.node) ?? [];

    console.log(`   📥 JustWatch에서 ${contents.length}개 콘텐츠 수신`);

    let synced = 0;
    let errors = 0;

    for (const jw of contents) {
      try {
        await syncSingleContent(jw);
        synced++;
      } catch (err) {
        console.error(`   ⚠️  콘텐츠 동기화 실패 (${jw.id}):`, err);
        errors++;
      }

      // TMDb API 레이트 리밋 방지 (40 req/s)
      await sleep(25);
    }

    console.log(`✅ JustWatch 동기화 완료: ${synced}개 성공, ${errors}개 실패`);
  } catch (error) {
    console.error('❌ JustWatch API 오류:', error);
    throw error;
  }
}

/**
 * 콘텐츠 1개 동기화 (JustWatch → TMDb 보강 → DB 저장)
 */
async function syncSingleContent(jw: JustWatchContent): Promise<void> {
  const tmdbId = jw.content.externalIds?.tmdbId;
  if (!tmdbId) return;  // TMDb ID 없으면 건너뜀

  const contentType = jw.objectType === 'MOVIE' ? 'movie' : 'tv';

  // TMDb에서 상세 정보 가져오기
  const tmdb = await fetchTmdbDetail(tmdbId, contentType);
  if (!tmdb) return;

  const genres = tmdb.genres?.map((g) => g.name) ?? [];
  const cast = tmdb.credits?.cast
    ?.slice(0, 5)
    .map((c) => c.name) ?? [];
  const director = tmdb.credits?.crew
    ?.find((c) => c.job === 'Director')?.name ?? null;

  await withTransaction(async (client) => {
    // 콘텐츠 upsert
    const result = await client.query(`
      INSERT INTO contents (
        tmdb_id, justwatch_id, content_type,
        title_ko, title_en, title_original,
        overview_ko, poster_url, backdrop_url,
        release_date, runtime_minutes,
        episode_count, season_count,
        genres, cast_names, director,
        tmdb_rating, last_synced_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,NOW())
      ON CONFLICT (tmdb_id) DO UPDATE SET
        title_ko        = EXCLUDED.title_ko,
        overview_ko     = EXCLUDED.overview_ko,
        poster_url      = EXCLUDED.poster_url,
        genres          = EXCLUDED.genres,
        cast_names      = EXCLUDED.cast_names,
        tmdb_rating     = EXCLUDED.tmdb_rating,
        last_synced_at  = NOW(),
        updated_at      = NOW()
      RETURNING id
    `, [
      tmdbId,
      jw.id,
      contentType,
      tmdb.title ?? tmdb.name ?? jw.content.title,
      tmdb.original_title ?? null,
      jw.content.originalTitle ?? null,
      tmdb.overview ?? null,
      tmdb.poster_path ? `${TMDB_IMAGE_BASE}${tmdb.poster_path}` : null,
      tmdb.backdrop_path ? `${TMDB_IMAGE_BASE}${tmdb.backdrop_path}` : null,
      tmdb.release_date ?? tmdb.first_air_date ?? null,
      tmdb.runtime ?? tmdb.episode_run_time?.[0] ?? null,
      tmdb.number_of_episodes ?? null,
      tmdb.number_of_seasons ?? null,
      genres,
      cast,
      director,
      tmdb.vote_average ?? null,
    ]);

    const contentId = result.rows[0]?.id;
    if (!contentId) return;

    // OTT 가용성 데이터 동기화
    if (jw.offers && jw.offers.length > 0) {
      // 기존 가용성 삭제 후 재삽입
      await client.query('DELETE FROM content_availability WHERE content_id = $1', [contentId]);

      for (const offer of jw.offers) {
        const platformId = getPlatformId(offer.package.packageId);
        if (!platformId) continue;

        await client.query(`
          INSERT INTO content_availability (
            content_id, platform_id, availability_type,
            price, deep_link_url, last_checked_at
          ) VALUES ($1,$2,$3,$4,$5,NOW())
          ON CONFLICT (content_id, platform_id, availability_type) DO UPDATE SET
            price           = EXCLUDED.price,
            deep_link_url   = EXCLUDED.deep_link_url,
            last_checked_at = NOW()
        `, [
          contentId,
          platformId,
          offer.monetizationType.toLowerCase(),
          offer.retailPrice ? Math.round(offer.retailPrice * 1000) : null,
          offer.standardWebURL ?? null,
        ]);
      }
    }
  });
}

/**
 * TMDb에서 콘텐츠 상세 정보 가져오기
 */
async function fetchTmdbDetail(
  tmdbId: number,
  type: 'movie' | 'tv'
): Promise<TmdbMovie | null> {
  try {
    const response = await axios.get(
      `${TMDB_BASE_URL}/${type}/${tmdbId}`,
      {
        params: {
          api_key: TMDB_KEY,
          language: 'ko-KR',
          append_to_response: 'credits',
        },
        timeout: 10000,
      }
    );
    return response.data;
  } catch {
    return null;
  }
}

function getPlatformId(justWatchProviderId: number): string | null {
  return Object.entries(KOREAN_OTT_PROVIDERS)
    .find(([, id]) => id === justWatchProviderId)?.[0] ?? null;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * 임베딩이 없는 콘텐츠 목록 조회 (임베딩 생성용)
 */
export async function getContentsWithoutEmbedding(limit = 100): Promise<{ id: string; title_ko: string; overview_ko: string; genres: string[]; mood_tags: string[] }[]> {
  return query(`
    SELECT id, title_ko, overview_ko, genres, mood_tags
    FROM contents
    WHERE embedding IS NULL
    LIMIT $1
  `, [limit]);
}

/**
 * 콘텐츠 임베딩 업데이트
 */
export async function updateContentEmbedding(
  contentId: string,
  embedding: number[]
): Promise<void> {
  await query(
    'UPDATE contents SET embedding = $1 WHERE id = $2',
    [`[${embedding.join(',')}]`, contentId]
  );
}
