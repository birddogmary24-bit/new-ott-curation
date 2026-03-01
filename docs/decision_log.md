# Decision Log — OTT 큐레이션 앱

> 중요한 기술·제품 의사결정을 시간순으로 기록합니다.
> 형식: 배경 → 선택지 → 결정 → 근거 → 영향

---

## D-002. CI/CD 도구: GitHub Actions 선택

- **날짜**: 2026-03
- **배경**: 소스 변경 시 자동 배포 파이프라인 필요. 기존에는 `setup-gcp.sh` 수동 실행만 존재.
- **검토한 선택지**
  - **GitHub Actions**: 소스 레포와 동일 위치, 무료 티어 충분, YAML 기반으로 복잡한 Job 의존성 표현 가능
  - Cloud Build (GCP): GCP 네이티브이나, 소스가 GitHub에 있어 트리거 연동 복잡
  - Jenkins: 자체 서버 필요, 운영 오버헤드 큼
- **결정**: GitHub Actions (`.github/workflows/deploy.yml`)
- **근거**: 소스가 GitHub에 있고 팀 규모가 작아 별도 CI 서버 없이 바로 사용 가능. GCP 공식 Actions(`google-github-actions/auth`) 지원으로 Cloud Run 배포 연동 간단.
- **트레이드오프**: GCP 외부에서 빌드되므로 Private 네트워크 자원 접근 시 Cloud SQL Auth Proxy 필요
- **영향**: `.github/workflows/` 디렉토리, `scripts/run-migrations.sh`

---

## D-001. 앱 프레임워크: Flutter 선택

- **날짜**: 2026-02 (초기 설계)
- **배경**: iOS + Android 동시 지원 필요. 네이티브 vs 크로스플랫폼 선택 필요.
- **검토한 선택지**
  - React Native: JS 생태계, 인력 구하기 쉬움
  - **Flutter**: 단일 코드베이스, 60fps 렌더링, Riverpod 생태계 성숙
  - 네이티브 (Swift + Kotlin): 최고 성능이지만 2배 공수
- **결정**: Flutter (Dart) + Riverpod 2.0 + GoRouter
- **근거**: 초기 팀 규모가 작은 상황에서 단일 코드베이스가 결정적. TikTok 스타일 세로 피드도 Flutter의 CustomScrollView로 충분한 성능.
- **영향**: `flutter_app/` 디렉토리 전체 구조

---

## D-002. 상태 관리: Riverpod 2.0 선택

- **날짜**: 2026-02 (초기 설계)
- **배경**: Flutter 상태 관리 라이브러리 다수 존재.
- **검토한 선택지**
  - Provider (구버전): 레거시
  - BLoC: 보일러플레이트 과다
  - **Riverpod 2.0**: 코드 생성(Freezed), 타입 안전, 테스트 쉬움
  - GetX: 간단하지만 아키텍처 불명확
- **결정**: Riverpod 2.0 (with code generation)
- **근거**: AsyncValue 패턴으로 로딩/에러/데이터 상태를 일관되게 처리. Freezed와 조합으로 불변 모델.
- **영향**: 모든 feature의 `presentation/providers/` 파일 구조

---

## D-003. 인증: Firebase Auth + 카카오/Apple/Google

- **날짜**: 2026-02 (초기 설계)
- **배경**: 한국 사용자에게 친숙한 소셜 로그인 필요. 카카오는 Firebase 직접 지원 없음.
- **검토한 선택지**
  - Firebase Auth만 (Google/Apple): 카카오 제외, 한국 타겟에 불리
  - Supabase Auth: 카카오 지원 제한적
  - **Firebase Auth + 서버 Custom Token (카카오)**: 카카오 SDK → 서버 검증 → Firebase Custom Token 발급
- **결정**: Firebase Auth (Apple/Google 네이티브) + Kakao SDK → Custom Token 방식
- **근거**: Firebase를 중심 인증 허브로 통일해서 서버 미들웨어 단순화. 카카오는 서버 우회로 연동.
- **영향**: `server/src/utils/firebase.ts`, `user.routes.ts /auth/kakao`

---

## D-004. 데이터베이스: PostgreSQL + pgvector + pg_trgm

- **날짜**: 2026-02 (초기 설계)
- **배경**: 관계형 데이터 (콘텐츠, 사용자, 평점) + 벡터 검색 + 한국어 퍼지 검색 동시 필요.
- **검토한 선택지**
  - PostgreSQL + Pinecone (별도 벡터 DB): 운영 복잡도 증가, 비용
  - **PostgreSQL + pgvector**: 단일 DB로 벡터/관계형 통합
  - MongoDB Atlas: 벡터 검색 지원하지만 ACID 약함
- **결정**: Cloud SQL PostgreSQL 15 + pgvector(1024차원) + pg_trgm(퍼지 검색)
- **근거**: 인프라 단순화. 초기 단계에서 pgvector HNSW 인덱스로 충분한 성능. 추후 Pinecone 분리 가능한 구조 유지.
- **영향**: `db/migrations/001~006.sql` 전체, 임베딩 벡터 차원 1024

---

## D-005. AI 임베딩 모델: Voyage AI voyage-multilingual-2

- **날짜**: 2026-02 (초기 설계)
- **배경**: 한국어 텍스트(콘텐츠 설명, 사용자 쿼리) 임베딩 품질이 추천 정확도의 핵심.
- **검토한 선택지**
  - OpenAI text-embedding-3-large: 영어 최적, 한국어 품질 2위
  - **Voyage voyage-multilingual-2**: 다국어 최적화, 1024차원
  - Cohere embed-multilingual: 비슷하지만 가격 높음
  - 자체 fine-tuning: 리소스 과다
- **결정**: Voyage AI `voyage-multilingual-2`
- **근거**: 한국어 벤치마크 성능 우수. 1024차원은 pgvector 메모리 효율과 검색 정확도의 균형점. 가격 대비 성능.
- **영향**: `embedding.service.ts`, DB의 `VECTOR(1024)` 타입

---

## D-006. 평점 집계: 조화평균 채택

- **날짜**: 2026-02 (초기 설계)
- **배경**: 별점 1점 테러, 팬덤 몰표 등 극단값이 평균을 왜곡하는 문제.
- **검토한 선택지**
  - 산술평균: 단순하지만 극단값에 취약
  - 중앙값: 분포 파악 어려움
  - **조화평균**: n / SUM(1/rating_i) — 왓챠피디아 방식
  - 베이지안 평균: 구현 복잡, 파라미터 튜닝 필요
- **결정**: 조화평균 (DB 트리거로 실시간 갱신)
- **근거**: 왓챠피디아 방식으로 한국 사용자에게 익숙. 낮은 평점의 가중치를 줄여 극단값 완화. 트리거로 INSERT/UPDATE/DELETE 모두 처리.
- **영향**: `db/migrations/003_user_tables.sql` `update_content_rating()` 함수

---

## D-007. 콘텐츠 데이터: JustWatch 비공식 GraphQL API

- **날짜**: 2026-02 (초기 설계)
- **배경**: 한국 OTT 5개 플랫폼의 콘텐츠 가용성을 실시간으로 알 수 있는 단일 소스 필요.
- **검토한 선택지**
  - 각 OTT API 직접 연동: Netflix는 API 없음, 각각 파트너십 필요
  - TMDb API만: 콘텐츠 메타데이터는 있지만 OTT 가용성 한국 데이터 부정확
  - **JustWatch 비공식 GraphQL + TMDb 보강**: 가용성 + 상세 메타데이터 분리
- **결정**: JustWatch GraphQL (비공식) + TMDb API 조합
- **근거**: JustWatch가 사실상 유일한 멀티OTT 가용성 집계 소스. 비공식이지만 수년째 안정적으로 운영 중. 공식 파트너십 체결 시 마이그레이션 용이하도록 서비스 레이어 분리.
- **트레이드오프**: 비공식 API 언제든 차단 가능. 중장기적으로 공식 파트너십 필요.
- **영향**: `content-sync.service.ts`, KOREAN_OTT_PROVIDERS 매핑

---

## D-008. 서버: Cloud Run (Node.js/TypeScript)

- **날짜**: 2026-02 (초기 설계)
- **배경**: API 서버 인프라 선택.
- **검토한 선택지**
  - App Engine: 더 쉽지만 커스터마이징 제한
  - GKE: 쿠버네티스, 운영 부담 큼
  - **Cloud Run**: 서버리스 컨테이너, 자동 스케일, 0→N 스케일
  - AWS Lambda: GCP 생태계 통일 측면에서 비효율
- **결정**: Cloud Run (Node.js 22 / TypeScript)
- **근거**: GCP 생태계 내에서 Firebase/Cloud SQL/Cloud Storage와 IAM으로 통합. 트래픽 없을 때 0 인스턴스로 비용 절감.
- **영향**: `server/Dockerfile`, GCP 배포 구성

---

## D-009. AI 콘텐츠 피드 스코어: 복합 공식

- **날짜**: 2026-02 (초기 설계)
- **배경**: AI 콘텐츠 관의 노출 순서 결정 알고리즘.
- **검토한 선택지**
  - 단순 최신순: 다양성 없음
  - 좋아요 순: 초기 콘텐츠 불이익 (cold-start)
  - **복합 스코어**: engagement + freshness + personalization + diversity
- **결정**: 4요소 복합 스코어 (배치 사전 계산 + 쿼리 시 개인화 적용)
  ```
  engagement(40%) + freshness(30%) + personalization(20%) + diversity(10%)
  ```
- **근거**: 양질의 오래된 콘텐츠도 freshness 감쇠로 새 콘텐츠에 기회 부여. personalization으로 개인 취향 반영. diversity는 v2에서 구현.
- **영향**: `004_ai_content_hall.sql` `compute_feed_engagement_score()`, `ai-hall.routes.ts` 피드 쿼리

---

## D-010. 업로드 방식: Cloud Storage Signed URL 직접 업로드

- **날짜**: 2026-02 (초기 설계)
- **배경**: 최대 500MB 동영상 업로드를 API 서버를 통해 중계하면 메모리/대역폭 부담.
- **검토한 선택지**
  - API 서버 중계 업로드: 단순하지만 서버 부하, 타임아웃 위험
  - **Cloud Storage Signed URL**: 클라이언트가 직접 GCS에 PUT
- **결정**: Signed URL 직접 업로드 (30분 유효)
- **근거**: 대용량 파일 처리를 서버에서 분리. Cloud Run 요청 타임아웃(60s 기본) 회피. GCS의 업로드 안정성 활용.
- **플로우**: 서버는 메타데이터 생성 + Signed URL 발급만 담당 → 앱이 직접 업로드 → 완료 후 서버에 알림
- **영향**: `ai-hall.routes.ts /upload`, `/upload-complete`
