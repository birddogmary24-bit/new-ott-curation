import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { initFirebase } from './utils/firebase';
import { initDb } from './db/client';
import { contentRoutes } from './routes/content.routes';
import { curationRoutes } from './routes/curation.routes';
import { aiHallRoutes } from './routes/ai-hall.routes';
import { communityRoutes } from './routes/community.routes';
import { userRoutes } from './routes/user.routes';
import { internalRoutes } from './routes/internal.routes';

const app = express();
const PORT = parseInt(process.env.PORT ?? '8080', 10);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 미들웨어
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://ott-curation-app.web.app']  // Firebase Hosting URL
    : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
}));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 헬스체크
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// API 라우트
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
app.use('/api/contents',   contentRoutes);
app.use('/api/curations',  curationRoutes);
app.use('/api/ai-hall',    aiHallRoutes);
app.use('/api/community',  communityRoutes);
app.use('/api/users',      userRoutes);

// 내부 전용 (Cloud Scheduler에서 호출, API Secret으로 보호)
app.use('/internal',       internalRoutes);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 404 / 에러 핸들러
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
app.use((_req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('[ERROR]', err.message, err.stack);
  res.status(500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message,
  });
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 서버 시작
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function bootstrap() {
  try {
    await initFirebase();
    await initDb();
    app.listen(PORT, () => {
      console.log(`✅ OTT Curation API 서버 시작: http://localhost:${PORT}`);
      console.log(`   환경: ${process.env.NODE_ENV ?? 'development'}`);
    });
  } catch (error) {
    console.error('❌ 서버 시작 실패:', error);
    process.exit(1);
  }
}

bootstrap();
