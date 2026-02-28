import * as admin from 'firebase-admin';

/**
 * Firebase Admin SDK 초기화
 * Cloud Run에서는 서비스 계정 자격증명 자동 감지
 */
export async function initFirebase(): Promise<void> {
  if (admin.apps.length > 0) return;  // 이미 초기화됨

  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID ?? process.env.GCP_PROJECT_ID,
    storageBucket: `${process.env.GCP_PROJECT_ID}.appspot.com`,
  });

  console.log('✅ Firebase Admin SDK 초기화 완료');
}

/**
 * Firebase Auth 토큰 검증
 * @returns DecodedIdToken
 */
export async function verifyFirebaseToken(token: string): Promise<admin.auth.DecodedIdToken> {
  return admin.auth().verifyIdToken(token);
}

/**
 * 카카오 로그인 커스텀 토큰 발급
 * 카카오 SDK로 얻은 사용자 정보를 Firebase 커스텀 토큰으로 변환
 */
export async function createCustomTokenForKakao(kakaoUid: string, email?: string): Promise<string> {
  const uid = `kakao:${kakaoUid}`;

  // Firebase 사용자가 없으면 생성
  try {
    await admin.auth().getUser(uid);
  } catch {
    await admin.auth().createUser({
      uid,
      email,
      displayName: `kakao_${kakaoUid}`,
    });
  }

  return admin.auth().createCustomToken(uid, { provider: 'kakao' });
}

export { admin };
