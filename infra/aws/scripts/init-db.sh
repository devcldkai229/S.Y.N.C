#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bước 9: khởi tạo database trên RDS (tạo DB + extension pgvector) — chạy 1 lần
# sau khi `envs/<env>` apply xong và TRƯỚC khi force-redeploy service.
#
# VÌ SAO CẦN: các service .NET tự `Database.MigrateAsync()` lúc khởi động, nên
# DATABASE phải tồn tại sẵn; AI service cần extension `vector`.
#
# CƠ CHẾ: RDS nằm trong private subnet, không mở public. Script mở SSM
# port-forward qua MỘT EC2 container-instance của ECS (đã có SSM agent + SG của
# nó nằm trong danh sách được RDS cho phép), rồi chạy psql qua localhost.
# Credential: Secrets Manager /sync/<env>/db/postgres-password + SSM db/pg-user.
#
# Yêu cầu máy chạy: aws cli v2, session-manager-plugin, psql, terraform.
#
# Usage:
#   ./init-db.sh                       # env=dev
#   ./init-db.sh -e prod
#   ./init-db.sh -e dev -p 55432       # đổi local port
#   ./init-db.sh -e dev -f custom.sql  # đổi file SQL
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Git Bash (Windows): không convert /sync/... secret paths sang C:\Program Files\Git\...
export MSYS_NO_PATHCONV=1

ENV="dev"
REGION="${AWS_REGION:-ap-southeast-1}"
LOCAL_PORT="55432"
SQL_FILE=""

while getopts "e:r:p:f:h" opt; do
  case "$opt" in
    e) ENV="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    p) LOCAL_PORT="$OPTARG" ;;
    f) SQL_FILE="$OPTARG" ;;
    h) sed -n '2,22p' "$0"; exit 0 ;;
    *) exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # infra/aws
ENV_DIR="$AWS_DIR/envs/$ENV"
[ -n "$SQL_FILE" ] || SQL_FILE="$SCRIPT_DIR/init-databases.sql"

# Windows Git Bash: terraform.exe không hiểu /e/... → E:/... (mixed path, không \)
# psql.exe: không truyền -f path (backslash / MSYS); pipe SQL qua stdin (bash mở file).
win_path() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$p"
  elif [[ "$p" =~ ^/([a-zA-Z])/(.*) ]]; then
    # fallback Git Bash drive letter: /e/foo → E:/foo
    echo "${BASH_REMATCH[1]^}:/${BASH_REMATCH[2]}"
  else
    printf '%s' "$p"
  fi
}
TF_ENV_DIR="$(win_path "$ENV_DIR")"

# ── Tiền kiểm ───────────────────────────────────────────────────────────────
for c in aws psql terraform; do
  command -v "$c" >/dev/null || { echo "✗ thiếu '$c'"; exit 1; }
done
command -v session-manager-plugin >/dev/null || {
  echo "✗ thiếu session-manager-plugin (AWS Session Manager plugin)"
  echo "  https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
  exit 1; }
[ -d "$ENV_DIR" ]   || { echo "✗ không thấy $ENV_DIR"; exit 1; }
[ -f "$SQL_FILE" ]  || { echo "✗ không thấy SQL file: $SQL_FILE"; exit 1; }

echo "→ Đọc outputs Terraform ($ENV)  [chdir=$TF_ENV_DIR]"
RDS_HOST="$(terraform -chdir="$TF_ENV_DIR" output -raw rds_endpoint)"
CLUSTER="$(terraform -chdir="$TF_ENV_DIR" output -raw cluster_name)"
[ -n "$RDS_HOST" ] || { echo "✗ không lấy được rds_endpoint"; exit 1; }

echo "→ Lấy credential master (password SM + user SSM; không dùng secret ghép sẵn)"
# TF: managed /sync/<env>/db/postgres-password + SSM db/pg-user (composer path).
DB_PASS="$(aws secretsmanager get-secret-value --region "$REGION" \
  --secret-id "/sync/${ENV}/db/postgres-password" --query SecretString --output text)"
DB_USER="$(aws ssm get-parameter --region "$REGION" \
  --name "/sync/${ENV}/db/pg-user" --query Parameter.Value --output text)"
[ -n "$DB_USER" ] && [ -n "$DB_PASS" ] && [ "$DB_PASS" != "None" ] || {
  echo "✗ không lấy được Username/Password (postgres-password / pg-user)"; exit 1; }

echo "→ Tìm ECS container-instance làm jump host (SSM)"
CI_ARN="$(aws ecs list-container-instances --region "$REGION" --cluster "$CLUSTER" \
  --query 'containerInstanceArns[0]' --output text)"
[ "$CI_ARN" != "None" ] && [ -n "$CI_ARN" ] || {
  echo "✗ cluster '$CLUSTER' chưa có container instance nào đang chạy."
  echo "  Kiểm tra ASG đã khởi động EC2 chưa rồi thử lại."; exit 1; }

INSTANCE_ID="$(aws ecs describe-container-instances --region "$REGION" \
  --cluster "$CLUSTER" --container-instances "$CI_ARN" \
  --query 'containerInstances[0].ec2InstanceId' --output text)"

# Xác nhận instance đã đăng ký SSM (agent online)
SSM_OK="$(aws ssm describe-instance-information --region "$REGION" \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || echo None)"
[ "$SSM_OK" = "Online" ] || {
  echo "✗ instance $INSTANCE_ID chưa Online trên SSM (status=$SSM_OK)."
  echo "  Đợi ~1-2 phút sau khi EC2 khởi động rồi chạy lại."; exit 1; }

echo "   jump host: $INSTANCE_ID"
echo "   RDS      : $RDS_HOST:5432  →  localhost:$LOCAL_PORT"

# ── Mở port-forward nền, đảm bảo dọn khi thoát ──────────────────────────────
SSM_PID=""
cleanup() {
  if [ -n "$SSM_PID" ] && kill -0 "$SSM_PID" 2>/dev/null; then
    echo "→ đóng SSM session"
    kill "$SSM_PID" 2>/dev/null || true
    wait "$SSM_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

aws ssm start-session --region "$REGION" \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$RDS_HOST\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"$LOCAL_PORT\"]}" \
  >/dev/null 2>&1 &
SSM_PID=$!

echo "→ chờ tunnel sẵn sàng..."
for i in $(seq 1 30); do
  if PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -p "$LOCAL_PORT" -U "$DB_USER" \
       -d postgres -c 'SELECT 1' >/dev/null 2>&1; then
    echo "   tunnel OK sau ${i}s"; break
  fi
  kill -0 "$SSM_PID" 2>/dev/null || { echo "✗ SSM session chết sớm"; exit 1; }
  sleep 1
  [ "$i" -eq 30 ] && { echo "✗ tunnel không lên sau 30s (kiểm tra SG của RDS có cho phép SG của ECS instance)"; exit 1; }
done

echo "→ chạy SQL: $SQL_FILE"
# stdin: bash mở path Git Bash; Windows psql.exe không cần -f (tránh No such file)
PGPASSWORD="$DB_PASS" psql -v ON_ERROR_STOP=1 \
  -h 127.0.0.1 -p "$LOCAL_PORT" -U "$DB_USER" -d postgres <"$SQL_FILE"

echo "→ kiểm tra kết quả"
PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -p "$LOCAL_PORT" -U "$DB_USER" -d postgres \
  -c "SELECT datname FROM pg_database WHERE datname LIKE 'sync%' ORDER BY 1;"
PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -p "$LOCAL_PORT" -U "$DB_USER" -d sync_ai \
  -c "SELECT extname FROM pg_extension WHERE extname='vector';"

echo ""
echo "✓ Init DB xong cho env=$ENV"
echo "→ Tiếp theo (bước 10): force redeploy để service nạp secret + chạy migration"
echo "  for s in gateway iam roadmap exercise nutrition marketplace order payment notification social ai ai-worker rcm; do"
echo "    aws ecs update-service --region $REGION --cluster $CLUSTER --service sync-${ENV}-\$s --force-new-deployment >/dev/null; done"
