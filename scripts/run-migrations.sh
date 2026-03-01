#!/usr/bin/env bash
# DB 마이그레이션 자동 실행 스크립트
# Cloud SQL Auth Proxy를 통해 PostgreSQL에 연결 후 마이그레이션 적용
# 사용: CI/CD (GitHub Actions) 또는 로컬 개발 환경

set -euo pipefail

PROXY_PORT=5432
MIGRATIONS_DIR="$(dirname "$0")/../db/migrations"

# ─── 환경변수 확인 ───────────────────────────────────────────────────────────
required_vars=(DB_USER DB_PASSWORD DB_NAME CLOUD_SQL_CONNECTION_NAME)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ 오류: 환경변수 $var 가 설정되지 않았습니다."
    exit 1
  fi
done

# ─── Cloud SQL Auth Proxy 시작 ────────────────────────────────────────────────
echo "▶ Cloud SQL Auth Proxy 시작 (포트 $PROXY_PORT)..."
./cloud-sql-proxy \
  --port "$PROXY_PORT" \
  "$CLOUD_SQL_CONNECTION_NAME" &
PROXY_PID=$!

# Proxy 종료 시 자동 정리
cleanup() {
  echo "▶ Cloud SQL Auth Proxy 종료 (PID: $PROXY_PID)"
  kill "$PROXY_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Proxy 준비 대기 (최대 30초)
echo "⏳ Proxy 연결 대기 중..."
for i in $(seq 1 30); do
  if pg_isready -h 127.0.0.1 -p "$PROXY_PORT" -U "$DB_USER" > /dev/null 2>&1; then
    echo "✅ Proxy 연결 성공"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "❌ 오류: Proxy 연결 타임아웃 (30초)"
    exit 1
  fi
  sleep 1
done

# ─── 마이그레이션 실행 ────────────────────────────────────────────────────────
export PGPASSWORD="$DB_PASSWORD"

echo "▶ 마이그레이션 파일 목록:"
ls -1 "$MIGRATIONS_DIR"/*.sql | sort

echo ""
echo "▶ 마이그레이션 실행 중..."

for migration_file in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
  filename=$(basename "$migration_file")
  echo "  → $filename 적용 중..."
  psql \
    -h 127.0.0.1 \
    -p "$PROXY_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -f "$migration_file" \
    --set ON_ERROR_STOP=1 \
    -q
  echo "  ✅ $filename 완료"
done

echo ""
echo "✅ 모든 마이그레이션 완료"
