import { Pool, PoolClient } from 'pg';

let pool: Pool;

/**
 * Cloud SQL (PostgreSQL) 연결 풀 초기화
 * Cloud Run에서는 Unix 소켓으로 Cloud SQL에 연결
 */
export async function initDb(): Promise<void> {
  const isProduction = process.env.NODE_ENV === 'production';

  const dbConfig = isProduction
    ? {
        // Cloud Run → Cloud SQL: Unix 소켓 연결
        host: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME ?? `${process.env.GCP_PROJECT_ID}:${process.env.GCP_REGION}:${process.env.GCP_SQL_INSTANCE_NAME ?? 'ott-curation-db'}`}`,
        database: process.env.DB_NAME ?? 'ott_curation',
        user: process.env.DB_USER ?? 'ott_app',
        password: process.env.DB_PASSWORD,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      }
    : {
        // 로컬 개발: Cloud SQL Auth Proxy (port 5433)
        host: '127.0.0.1',
        port: 5433,
        database: process.env.DB_NAME ?? 'ott_curation',
        user: process.env.DB_USER ?? 'ott_app',
        password: process.env.DB_PASSWORD,
        max: 5,
      };

  pool = new Pool(dbConfig);

  // pgvector 타입 등록
  pool.on('connect', async (client) => {
    await client.query("SET TIME ZONE 'Asia/Seoul'");
  });

  // 연결 테스트
  const client = await pool.connect();
  await client.query('SELECT 1');
  client.release();

  console.log('✅ DB 연결 성공');
}

export function getPool(): Pool {
  if (!pool) throw new Error('DB가 초기화되지 않았습니다. initDb()를 먼저 호출하세요.');
  return pool;
}

/** 트랜잭션 헬퍼 */
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/** 쿼리 헬퍼 (간단한 SELECT에 사용) */
export async function query<T = Record<string, unknown>>(
  text: string,
  values?: unknown[]
): Promise<T[]> {
  const result = await getPool().query(text, values);
  return result.rows as T[];
}

/** 단일 결과 쿼리 */
export async function queryOne<T = Record<string, unknown>>(
  text: string,
  values?: unknown[]
): Promise<T | null> {
  const rows = await query<T>(text, values);
  return rows[0] ?? null;
}
