#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD=false
INFRA_ONLY=false
OPTIONAL=false
for arg in "$@"; do
  case "$arg" in
    --build) BUILD=true ;;
    --infra-only) INFRA_ONLY=true ;;
    --optional) OPTIONAL=true ;;
  esac
done

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit secrets before full test."
fi

PROFILES=()
if [[ "$INFRA_ONLY" != true ]]; then
  PROFILES+=(--profile app --profile ui)
fi
if [[ "$OPTIONAL" == true ]]; then
  PROFILES+=(--profile optional)
fi

CMD=(docker compose "${PROFILES[@]}" up -d)
if [[ "$BUILD" == true ]]; then
  CMD+=(--build)
fi

echo "> ${CMD[*]}"
"${CMD[@]}"

if [[ "$INFRA_ONLY" == true ]]; then
  echo "Infra ready."
  exit 0
fi

cat <<EOF

Stack URLs:
  Gateway:     http://localhost:5057
  Admin web:   http://localhost:3000
  Flutter web: http://localhost:3002
EOF
