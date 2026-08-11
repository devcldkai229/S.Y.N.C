#!/usr/bin/env bash
# Rolling deploy: đăng ký task-def revision mới với image mới rồi update service.
# Usage: ecs-deploy.sh <cluster> <service> <image>
# Env:
#   ECS_MIN_DESIRED  — if set (e.g. 1) and current desiredCount is below it, scale up
#                      before waiting so a parked (desired=0) service actually starts.
#   AWS_REGION       — used when injecting AwsLocation__* for order/social
# Requires: aws cli. Optional: jq — fallback python3/python nếu không có jq.
set -euo pipefail

CLUSTER="$1"; SERVICE="$2"; IMAGE="$3"
MIN_DESIRED="${ECS_MIN_DESIRED:-}"
LOC_REGION="${AWS_REGION:-ap-southeast-1}"
LOC_PLACE="${AWS_LOCATION_PLACE_INDEX:-sync-place-index}"
LOC_ROUTE="${AWS_LOCATION_ROUTE_CALCULATOR:-sync-route-calculator}"
LOC_PROVIDER="${AWS_LOCATION_DATA_PROVIDER:-Grab}"

echo "→ Rolling deploy $SERVICE on $CLUSTER with $IMAGE"

# Task-def hiện tại của service
SVC_JSON=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0]' --output json)
if [ -z "$SVC_JSON" ] || [ "$SVC_JSON" = "null" ]; then
  echo "✗ Service not found: $SERVICE on $CLUSTER" >&2
  exit 1
fi

# shellcheck disable=SC2016
_extract() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$SVC_JSON" | jq -r --arg k "$key" '.[$k] // empty'
  else
    local py=python3
    command -v python3 >/dev/null 2>&1 || py=python
    printf '%s' "$SVC_JSON" | "$py" -c "import json,sys; d=json.load(sys.stdin); print(d.get(sys.argv[1],'') if d.get(sys.argv[1]) is not None else '')" "$key"
  fi
}

TD_ARN=$(_extract taskDefinition)
DESIRED=$(_extract desiredCount)
DESIRED="${DESIRED:-0}"
echo "  current desiredCount=$DESIRED taskDefinition=$TD_ARN"

# Lấy JSON task-def, thay image + optionally inject Location env, strip read-only fields
TD_JSON=$(aws ecs describe-task-definition --task-definition "$TD_ARN" \
  --query 'taskDefinition' --output json)

# Terraform ignores task_definition after create — live TD may lack AwsLocation__*.
# Inject/ensure for order + social so CI deploy is the carrier for Location config.
NEED_LOCATION=0
case "$SERVICE" in
  *-order|*-social) NEED_LOCATION=1 ;;
esac

patch_td() {
  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    local py=python3
    command -v python3 >/dev/null 2>&1 || py=python
    "$py" -c '
import json, sys

img, service, need_loc, region, place, route, provider = sys.argv[1:8]
td = json.load(sys.stdin)
c0 = td["containerDefinitions"][0]
c0["image"] = img

if need_loc == "1":
    env = c0.get("environment") or []
    by_name = {e["name"]: e for e in env if "name" in e}
    for k, v in {
        "AwsLocation__Region": region,
        "AwsLocation__PlaceIndexName": place,
    }.items():
        by_name[k] = {"name": k, "value": v}
    # social also needs route calculator
    if service.endswith("-social") or service.endswith("social"):
        by_name["AwsLocation__RouteCalculatorName"] = {
            "name": "AwsLocation__RouteCalculatorName", "value": route
        }
        by_name["AwsLocation__DataProvider"] = {
            "name": "AwsLocation__DataProvider", "value": provider
        }
    c0["environment"] = list(by_name.values())
    print("  ensured AwsLocation env on container", file=sys.stderr)

for k in (
    "taskDefinitionArn", "revision", "status", "requiresAttributes",
    "compatibilities", "registeredAt", "registeredBy",
):
    td.pop(k, None)
json.dump(td, sys.stdout, separators=(",", ":"))
' "$IMAGE" "$SERVICE" "$NEED_LOCATION" "$LOC_REGION" "$LOC_PLACE" "$LOC_ROUTE" "$LOC_PROVIDER"
  elif command -v jq >/dev/null 2>&1; then
    # image only via jq if python missing (Location inject requires python)
    if [ "$NEED_LOCATION" = "1" ]; then
      echo "✗ python required to inject AwsLocation env for $SERVICE" >&2
      exit 1
    fi
    jq --arg IMAGE "$IMAGE" '
      .containerDefinitions[0].image = $IMAGE
      | del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
    '
  else
    echo "✗ cần python (hoặc jq) để sửa task definition" >&2
    exit 1
  fi
}

NEW_TD=$(printf '%s' "$TD_JSON" | patch_td)

NEW_ARN=$(aws ecs register-task-definition --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)
echo "  registered $NEW_ARN"

UPDATE_ARGS=(
  --cluster "$CLUSTER"
  --service "$SERVICE"
  --task-definition "$NEW_ARN"
  --force-new-deployment
)

if [ -n "$MIN_DESIRED" ] && [ "$DESIRED" -lt "$MIN_DESIRED" ]; then
  echo "  desiredCount $DESIRED < ECS_MIN_DESIRED=$MIN_DESIRED — scaling up"
  UPDATE_ARGS+=(--desired-count "$MIN_DESIRED")
fi

aws ecs update-service "${UPDATE_ARGS[@]}" >/dev/null

echo "  waiting services-stable ..."
if ! aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE"; then
  echo "✗ wait services-stable failed (capacity ASG max=0? crash loop? circuit breaker?)" >&2
  aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,events:events[0:5]}' \
    --output json >&2 || true
  exit 1
fi

ROLL_STATE=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].deployments[?status==`PRIMARY`]|[0].rolloutState' --output text)
echo "  primary rolloutState=$ROLL_STATE"
if [ "$ROLL_STATE" = "FAILED" ]; then
  echo "✗ Deploy failed: rolloutState=FAILED (có thể đã rollback về task-def cũ)" >&2
  exit 1
fi

RUNNING_TD=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)
RUNNING_IMAGE=$(aws ecs describe-task-definition --task-definition "$RUNNING_TD" \
  --query 'taskDefinition.containerDefinitions[0].image' --output text)
echo "  running image=$RUNNING_IMAGE"
if [ "$RUNNING_IMAGE" != "$IMAGE" ]; then
  echo "✗ Deploy mismatch: expected $IMAGE but primary TD has $RUNNING_IMAGE" >&2
  exit 1
fi

FINAL_DESIRED=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].desiredCount' --output text)
FINAL_RUNNING=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].runningCount' --output text)
echo "  desired=$FINAL_DESIRED running=$FINAL_RUNNING"
if [ "${FINAL_DESIRED:-0}" = "0" ]; then
  echo "⚠ Service desiredCount is still 0 — image registered but NO task is running (fleet parked)." >&2
  echo "  Unpark: raise ASG max/desired for ecs-ondemand + ecs-spot, then set service desired >= 1." >&2
fi

echo "✓ $SERVICE deployed"
