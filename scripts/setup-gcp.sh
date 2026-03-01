#!/bin/bash
# ============================================================
# OTT Curation App - GCP 전체 자동 설정 스크립트
# 사용법: ./scripts/setup-gcp.sh YOUR_BILLING_ACCOUNT_ID
# 예시: ./scripts/setup-gcp.sh 012345-ABCDEF-GHIJKL
# ============================================================

set -e  # 오류 발생 시 즉시 중단

BILLING_ACCOUNT_ID="${1:?❌ 결제 계정 ID를 인수로 전달하세요. 예: ./scripts/setup-gcp.sh 012345-ABCDEF-GHIJKL}"

# .env 파일 로드
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env 파일이 없습니다. .env.example을 복사해서 .env를 만들어주세요."
  exit 1
fi

PROJECT_ID="${GCP_PROJECT_ID:-ott-curation-app}"
REGION="${GCP_REGION:-asia-northeast3}"
SQL_INSTANCE="${GCP_SQL_INSTANCE_NAME:-ott-curation-db}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 OTT Curation App - GCP 자동 설정 시작"
echo "   프로젝트 ID : $PROJECT_ID"
echo "   리전        : $REGION (서울)"
echo "   결제 계정   : $BILLING_ACCOUNT_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: GCP 프로젝트 생성
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "📁 [1/9] GCP 프로젝트 생성..."

# 이미 존재하는 경우 재사용
if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
  echo "   ↳ 프로젝트 '$PROJECT_ID' 이미 존재함. 재사용합니다."
else
  gcloud projects create "$PROJECT_ID" \
    --name="OTT Curation App" \
    --labels="env=production,app=ott-curation"
  echo "   ✅ 프로젝트 생성 완료"
fi

# 현재 프로젝트로 설정
gcloud config set project "$PROJECT_ID"

# 결제 계정 연동
gcloud billing projects link "$PROJECT_ID" \
  --billing-account="$BILLING_ACCOUNT_ID"
echo "   ✅ 결제 계정 연동 완료"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 2: 필요한 API 활성화
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🔌 [2/9] 필요한 API 활성화 중..."

APIS=(
  "sqladmin.googleapis.com"           # Cloud SQL
  "run.googleapis.com"                # Cloud Run
  "storage.googleapis.com"            # Cloud Storage
  "cloudfunctions.googleapis.com"     # Cloud Functions
  "cloudscheduler.googleapis.com"     # Cloud Scheduler
  "secretmanager.googleapis.com"      # Secret Manager
  "firebase.googleapis.com"           # Firebase
  "identitytoolkit.googleapis.com"    # Firebase Auth
  "cloudbuild.googleapis.com"         # Cloud Build (배포용)
  "artifactregistry.googleapis.com"   # Artifact Registry (Docker)
  "iam.googleapis.com"                # IAM
  "cloudresourcemanager.googleapis.com" # 리소스 관리
)

gcloud services enable "${APIS[@]}"
echo "   ✅ API 활성화 완료 (${#APIS[@]}개)"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: 서비스 계정 생성 및 권한 설정
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🔐 [3/9] 서비스 계정 및 IAM 설정..."

SA_NAME="ott-curation-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="OTT Curation App Service Account"
fi

# Cloud Run이 Cloud SQL, Storage, Secret Manager에 접근할 수 있도록 권한 부여
ROLES=(
  "roles/cloudsql.client"
  "roles/storage.admin"
  "roles/secretmanager.secretAccessor"
  "roles/firebase.admin"
  "roles/cloudscheduler.admin"
  "roles/cloudfunctions.invoker"
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE" \
    --quiet
done

echo "   ✅ 서비스 계정 및 권한 설정 완료"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: Cloud SQL 인스턴스 생성
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🗄️  [4/9] Cloud SQL PostgreSQL 인스턴스 생성..."
echo "   ⏳ 인스턴스 생성에 5~10분 소요됩니다..."

if ! gcloud sql instances describe "$SQL_INSTANCE" &>/dev/null; then
  gcloud sql instances create "$SQL_INSTANCE" \
    --database-version=POSTGRES_15 \
    --region="$REGION" \
    --tier=db-f1-micro \
    --storage-type=SSD \
    --storage-size=20GB \
    --storage-auto-increase \
    --availability-type=ZONAL \
    --no-assign-ip \
    --enable-google-private-path \
    --database-flags="cloudsql.enable_pgvector=on,cloudsql.enable_pg_trgm=on"
  echo "   ✅ Cloud SQL 인스턴스 생성 완료"
else
  echo "   ↳ Cloud SQL 인스턴스 이미 존재함. 재사용합니다."
fi

# DB 사용자 생성
gcloud sql users create "${DB_USER}" \
  --instance="$SQL_INSTANCE" \
  --password="${DB_PASSWORD}" 2>/dev/null || echo "   ↳ DB 사용자 이미 존재함"

# DB 생성
gcloud sql databases create "${DB_NAME}" \
  --instance="$SQL_INSTANCE" 2>/dev/null || echo "   ↳ 데이터베이스 이미 존재함"

echo "   ✅ PostgreSQL DB 설정 완료"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 5: Cloud Storage 버킷 생성
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🪣  [5/9] Cloud Storage 버킷 생성..."

create_bucket() {
  local BUCKET_NAME="$1"
  local PUBLIC="$2"

  if ! gsutil ls "gs://${BUCKET_NAME}" &>/dev/null; then
    gsutil mb -p "$PROJECT_ID" -l "$REGION" -c STANDARD "gs://${BUCKET_NAME}"
    gsutil lifecycle set scripts/bucket-lifecycle.json "gs://${BUCKET_NAME}"
    if [ "$PUBLIC" = "public" ]; then
      gsutil iam ch allUsers:objectViewer "gs://${BUCKET_NAME}"
    fi
    echo "   ✅ gs://${BUCKET_NAME} 생성"
  else
    echo "   ↳ gs://${BUCKET_NAME} 이미 존재함"
  fi
}

create_bucket "${GCS_VIDEO_BUCKET:-ott-curation-ai-videos}" "private"
create_bucket "${GCS_THUMBNAIL_BUCKET:-ott-curation-thumbnails}" "public"
create_bucket "${GCS_AVATAR_BUCKET:-ott-curation-avatars}" "public"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 6: Secret Manager에 API 키 등록
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🔑 [6/9] Secret Manager에 API 키 등록..."

store_secret() {
  local SECRET_NAME="$1"
  local SECRET_VALUE="$2"

  if [ -z "$SECRET_VALUE" ]; then
    echo "   ⚠️  $SECRET_NAME 값이 비어있어 건너뜁니다 (.env에서 설정해주세요)"
    return
  fi

  if gcloud secrets describe "$SECRET_NAME" &>/dev/null; then
    echo "$SECRET_VALUE" | gcloud secrets versions add "$SECRET_NAME" --data-file=-
    echo "   🔄 $SECRET_NAME 업데이트"
  else
    echo "$SECRET_VALUE" | gcloud secrets create "$SECRET_NAME" \
      --data-file=- \
      --replication-policy=user-managed \
      --locations="$REGION"
    echo "   ✅ $SECRET_NAME 등록"
  fi
}

store_secret "gemini-api-key" "$GEMINI_API_KEY"
store_secret "voyage-api-key" "$VOYAGE_API_KEY"
store_secret "tmdb-api-key" "$TMDB_API_KEY"
store_secret "db-password" "$DB_PASSWORD"
store_secret "api-secret-key" "$API_SECRET_KEY"

if [ -n "$JUSTWATCH_API_KEY" ]; then
  store_secret "justwatch-api-key" "$JUSTWATCH_API_KEY"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 7: DB 스키마 마이그레이션 실행
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "📊 [7/9] DB 스키마 마이그레이션 실행..."
echo "   ⏳ Cloud SQL Proxy를 통해 마이그레이션 실행..."

# Cloud SQL Auth Proxy 설치 (없는 경우)
if ! command -v cloud-sql-proxy &>/dev/null; then
  echo "   📥 Cloud SQL Auth Proxy 설치 중..."
  curl -o /usr/local/bin/cloud-sql-proxy \
    "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.darwin.amd64"
  chmod +x /usr/local/bin/cloud-sql-proxy
fi

# Cloud SQL Proxy 백그라운드 실행
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe "$SQL_INSTANCE" \
  --format="value(connectionName)")

cloud-sql-proxy "$INSTANCE_CONNECTION_NAME" --port=5433 &
PROXY_PID=$!
sleep 3

# psql로 마이그레이션 실행
export PGPASSWORD="$DB_PASSWORD"
PSQL_CMD="psql -h 127.0.0.1 -p 5433 -U $DB_USER -d $DB_NAME"

for MIGRATION_FILE in db/migrations/*.sql; do
  echo "   📄 실행: $MIGRATION_FILE"
  $PSQL_CMD -f "$MIGRATION_FILE"
done

# Proxy 종료
kill $PROXY_PID 2>/dev/null
echo "   ✅ DB 마이그레이션 완료"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 8: Cloud Run API 서버 배포
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🚀 [8/9] Cloud Run API 서버 배포..."

cd server

gcloud run deploy ott-curation-api \
  --source=. \
  --platform=managed \
  --region="$REGION" \
  --service-account="$SA_EMAIL" \
  --set-cloudsql-instances="$INSTANCE_CONNECTION_NAME" \
  --set-env-vars="NODE_ENV=production,GCP_PROJECT_ID=$PROJECT_ID,DB_NAME=$DB_NAME,DB_USER=$DB_USER,GCP_REGION=$REGION,GCS_VIDEO_BUCKET=${GCS_VIDEO_BUCKET:-ott-curation-ai-videos},GCS_THUMBNAIL_BUCKET=${GCS_THUMBNAIL_BUCKET:-ott-curation-thumbnails},GCS_AVATAR_BUCKET=${GCS_AVATAR_BUCKET:-ott-curation-avatars}" \
  --set-secrets="DB_PASSWORD=db-password:latest,ANTHROPIC_API_KEY=anthropic-api-key:latest,VOYAGE_API_KEY=voyage-api-key:latest,TMDB_API_KEY=tmdb-api-key:latest,API_SECRET_KEY=api-secret-key:latest" \
  --min-instances=0 \
  --max-instances=10 \
  --memory=1Gi \
  --cpu=1 \
  --allow-unauthenticated \
  --port=8080

cd ..

# Cloud Run URL 가져오기
API_URL=$(gcloud run services describe ott-curation-api \
  --region="$REGION" \
  --format="value(status.url)")

echo "   ✅ Cloud Run 배포 완료: $API_URL"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 9: Cloud Scheduler CRON 설정
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "⏰ [9/9] Cloud Scheduler CRON 설정..."

# Cloud Scheduler에 사용할 서비스 계정에 invoker 권한
gcloud run services add-iam-policy-binding ott-curation-api \
  --region="$REGION" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.invoker"

# 헬퍼 함수
create_scheduler() {
  local JOB_NAME="$1"
  local SCHEDULE="$2"
  local URI="$3"
  local DESCRIPTION="$4"

  if gcloud scheduler jobs describe "$JOB_NAME" --location="$REGION" &>/dev/null; then
    gcloud scheduler jobs update http "$JOB_NAME" \
      --location="$REGION" \
      --schedule="$SCHEDULE" \
      --uri="$URI" \
      --http-method=POST \
      --oidc-service-account-email="$SA_EMAIL" \
      --time-zone="Asia/Seoul"
  else
    gcloud scheduler jobs create http "$JOB_NAME" \
      --location="$REGION" \
      --schedule="$SCHEDULE" \
      --uri="$URI" \
      --http-method=POST \
      --oidc-service-account-email="$SA_EMAIL" \
      --time-zone="Asia/Seoul" \
      --description="$DESCRIPTION"
  fi
  echo "   ✅ $JOB_NAME ($SCHEDULE KST)"
}

create_scheduler "content-sync-daily" \
  "0 4 * * *" \
  "${API_URL}/internal/sync/content" \
  "매일 04:00 KST - JustWatch+TMDb 콘텐츠 동기화"

create_scheduler "compute-embeddings-daily" \
  "0 5 * * *" \
  "${API_URL}/internal/sync/embeddings" \
  "매일 05:00 KST - 콘텐츠 임베딩 생성"

create_scheduler "nightly-curation" \
  "0 3 * * *" \
  "${API_URL}/internal/curation/nightly" \
  "매일 03:00 KST - 개인화 큐레이션 사전 계산"

create_scheduler "feed-score-update" \
  "*/15 * * * *" \
  "${API_URL}/internal/ai-hall/update-scores" \
  "15분마다 - AI Hall 피드 스코어 갱신"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 완료
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 GCP 설정 완료!"
echo ""
echo "   Cloud Run API URL: $API_URL"
echo "   GCP Console: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"
echo ""
echo "📱 다음 단계: Flutter 앱 설정"
echo "   1. google-services.json / GoogleService-Info.plist 다운로드"
echo "      https://console.firebase.google.com"
echo "   2. flutter_app/lib/core/config/app_config.dart에 API URL 입력"
echo "      API_BASE_URL = '$API_URL'"
echo "   3. flutter pub get && flutter pub run build_runner build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
