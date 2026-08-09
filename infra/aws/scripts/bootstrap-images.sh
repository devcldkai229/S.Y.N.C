#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bootstrap images: build & push tag ":bootstrap" cho 12 ECR repo.
#
# VÌ SAO CẦN: Terraform tạo ECS task-definition với image_tag = "bootstrap".
# Nếu ECR chưa có tag đó → task crash-loop và `terraform apply` có thể treo ở
# wait. Chạy script này SAU `envs/shared` (đã có ECR) và TRƯỚC `envs/dev` apply.
#
# ⚠️ KIẾN TRÚC: ECS chạy trên EC2 t4g (Graviton = ARM64) → PHẢI build linux/arm64.
#    Build trên x86 (Windows/Linux Intel) sẽ dùng QEMU → chậm nhưng chạy được.
#    Trên Apple Silicon là native → nhanh.
#
# Usage:
#   ./bootstrap-images.sh                          # tất cả service, tag=bootstrap
#   ./bootstrap-images.sh -s iam -s ai             # chỉ vài service
#   ./bootstrap-images.sh -t v0 -r ap-southeast-1  # đổi tag / region
#   PLATFORM=linux/amd64 ./bootstrap-images.sh     # nếu cluster đổi sang x86
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"
TAG="bootstrap"
PLATFORM="${PLATFORM:-linux/arm64}"     # t4g Graviton
ACCOUNT_ID="${ACCOUNT_ID:-}"
SELECTED=()

while getopts "s:t:r:a:h" opt; do
  case "$opt" in
    s) SELECTED+=("$OPTARG") ;;
    t) TAG="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    a) ACCOUNT_ID="$OPTARG" ;;
    h) sed -n '2,20p' "$0"; exit 0 ;;
    *) exit 1 ;;
  esac
done

# Chạy từ gốc repo dù gọi ở đâu
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

# 12 repo — khớp envs/shared/main.tf + app-cicd.yml (ai-worker dùng chung image "ai")
ALL_SERVICES=(gateway iam roadmap exercise nutrition marketplace order payment notification social ai rcm)
SERVICES=("${SELECTED[@]:-${ALL_SERVICES[@]}}")

# service → context | dockerfile | project(csproj, rỗng nếu không phải .NET)
meta() {
  case "$1" in
    gateway)      echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Gateway/Gateway.API.csproj" ;;
    iam)          echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Iam/Iam.API/Iam.API.csproj" ;;
    roadmap)      echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Roadmap/Roadmap.API/Roadmap.API.csproj" ;;
    exercise)     echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Exercise/Exercise.API/Exercise.API.csproj" ;;
    nutrition)    echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Nutrition/Nutrition.API/Nutrition.API.csproj" ;;
    marketplace)  echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Marketplace/Marketplace.API/Marketplace.API.csproj" ;;
    order)        echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Order/Order.API/Order.API.csproj" ;;
    payment)      echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Payment/Payment.API/Payment.API.csproj" ;;
    notification) echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Notification/Notification.API/Notification.API.csproj" ;;
    social)       echo "core/SyncPlatform|core/SyncPlatform/Dockerfile|src/Services/Social/Social.API/Social.API.csproj" ;;
    ai)           echo "ai/sync-agent-service|ai/sync-agent-service/Dockerfile|" ;;
    rcm)          echo "ai/sync-rcm-service|ai/sync-rcm-service/Dockerfile|" ;;
    *)            echo "" ;;
  esac
}

# ── Tiền kiểm ───────────────────────────────────────────────────────────────
command -v aws >/dev/null    || { echo "✗ thiếu aws cli"; exit 1; }
command -v docker >/dev/null || { echo "✗ thiếu docker"; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo "✗ thiếu docker buildx"; exit 1; }

[ -n "$ACCOUNT_ID" ] || ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "┌──────────────────────────────────────────────"
echo "│ Registry : $REGISTRY"
echo "│ Tag      : $TAG"
echo "│ Platform : $PLATFORM"
echo "│ Services : ${SERVICES[*]}"
echo "└──────────────────────────────────────────────"

# Buildx builder hỗ trợ cross-platform (QEMU khi build ARM trên x86)
if ! docker buildx inspect sync-builder >/dev/null 2>&1; then
  echo "→ tạo buildx builder 'sync-builder'"
  docker run --privileged --rm tonistiigi/binfmt --install arm64 >/dev/null 2>&1 || true
  docker buildx create --name sync-builder --driver docker-container --use >/dev/null
fi
docker buildx use sync-builder

echo "→ ECR login"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY" >/dev/null

FAILED=()
for svc in "${SERVICES[@]}"; do
  M="$(meta "$svc")"
  if [ -z "$M" ]; then echo "✗ service không hợp lệ: $svc"; FAILED+=("$svc"); continue; fi
  IFS='|' read -r CTX DF PROJECT <<< "$M"
  IMAGE="${REGISTRY}/sync/${svc}:${TAG}"

  echo ""
  echo "▶ [$svc] build → $IMAGE"

  # Repo phải tồn tại (envs/shared đã apply). Nếu chưa có thì báo rõ.
  if ! aws ecr describe-repositories --region "$REGION" --repository-names "sync/${svc}" >/dev/null 2>&1; then
    echo "✗ [$svc] ECR repo 'sync/${svc}' chưa tồn tại — apply infra/aws/envs/shared trước."
    FAILED+=("$svc"); continue
  fi

  BUILD_ARGS=()
  [ -n "$PROJECT" ] && BUILD_ARGS+=(--build-arg "PROJECT=${PROJECT}")

  if docker buildx build \
        --platform "$PLATFORM" \
        -f "$DF" \
        "${BUILD_ARGS[@]}" \
        -t "$IMAGE" \
        --push \
        "$CTX"; then
    echo "✓ [$svc] pushed"
  else
    echo "✗ [$svc] FAILED"
    FAILED+=("$svc")
  fi
done

echo ""
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "✗ Thất bại: ${FAILED[*]}"
  echo "  Chạy lại riêng: ./bootstrap-images.sh -s <service>"
  exit 1
fi

echo "✓ Xong toàn bộ. Kiểm tra:"
echo "  aws ecr describe-images --region $REGION --repository-name sync/iam \\"
echo "    --query 'imageDetails[].imageTags' --output table"
echo ""
echo "→ Tiếp theo: cd infra/aws/envs/dev && terraform apply"
