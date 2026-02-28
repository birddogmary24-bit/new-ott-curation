import { Request, Response, NextFunction } from 'express';
import { verifyFirebaseToken } from '../utils/firebase';
import { queryOne } from '../db/client';

// Firebase UID를 req에 추가하기 위한 타입 확장
declare global {
  namespace Express {
    interface Request {
      uid?: string;
      userId?: string;        // DB의 profiles.id (UUID)
      firebaseUser?: import('firebase-admin').auth.DecodedIdToken;
    }
  }
}

/**
 * Firebase Auth 토큰 검증 미들웨어
 * Authorization: Bearer <firebase_id_token>
 */
export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: '인증 토큰이 필요합니다.' });
    return;
  }

  const token = authHeader.slice(7);

  try {
    const decoded = await verifyFirebaseToken(token);
    req.uid = decoded.uid;
    req.firebaseUser = decoded;

    // DB에서 profiles.id (UUID) 조회
    const profile = await queryOne<{ id: string }>(
      'SELECT id FROM profiles WHERE firebase_uid = $1',
      [decoded.uid]
    );

    if (profile) {
      req.userId = profile.id;
    }

    next();
  } catch {
    res.status(401).json({ error: '유효하지 않은 토큰입니다.' });
  }
}

/**
 * 선택적 인증 미들웨어 (로그인 없이도 접근 가능하나, 로그인 시 사용자 정보 포함)
 */
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    try {
      const decoded = await verifyFirebaseToken(token);
      req.uid = decoded.uid;
      req.firebaseUser = decoded;

      const profile = await queryOne<{ id: string }>(
        'SELECT id FROM profiles WHERE firebase_uid = $1',
        [decoded.uid]
      );
      if (profile) req.userId = profile.id;
    } catch {
      // 토큰이 잘못됐어도 진행 (선택적 인증)
    }
  }

  next();
}

/**
 * 내부 API 보호 미들웨어 (Cloud Scheduler 전용)
 * X-Internal-Secret 헤더 검증
 */
export function requireInternalSecret(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const secret = req.headers['x-internal-secret'];
  if (secret !== process.env.API_SECRET_KEY) {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }
  next();
}
