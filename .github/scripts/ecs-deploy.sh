#!/usr/bin/env bash
# Rolling deploy: đăng ký task-def revision mới với image mới rồi update service.
# Usage: ecs-deploy.sh <cluster> <service> <image>
# Env:
#   ECS_MIN_DESIRED   — scale up only if current desired is ALREADY > 0 and still below this
#                       (won't un-park desired=0 workers). Use ECS_FORCE_UNPARK=1 to override.
#   ECS_FORCE_UNPARK  — if 1 and ECS_MIN_DESIRED set, scale 0 → MIN
#   ECS_TASK_MEMORY   — optional override (e.g. 384) for packing on small t4g instances
#   ECS_TASK_CPU      — optional override (e.g. 128)
#   AWS_REGION        — used when injecting AwsLocation__* for order/social
set -euo pipefail

CLUSTER="$1"; SERVICE="$2"; IMAGE="$3"
MIN_DESIRED="${ECS_MIN_DESIRED:-}"
FORCE_UNPARK="${ECS_FORCE_UNPARK:-0}"
TASK_MEMORY="${ECS_TASK_MEMORY:-}"
TASK_CPU="${ECS_TASK_CPU:-}"
LOC_REGION="${AWS_REGION:-ap-southeast-1}"
LOC_PLACE="${AWS_LOCATION_PLACE_INDEX:-sync-place-index}"
LOC_ROUTE="${AWS_LOCATION_ROUTE_CALCULATOR:-sync-route-calculator}"
LOC_PROVIDER="${AWS_LOCATION_DATA_PROVIDER:-Grab}"

echo "→ Rolling deploy $SERVICE on $CLUSTER with $IMAGE"

SVC_JSON=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0]' --output json)
if [ -z "$SVC_JSON" ] || [ "$SVC_JSON" = "null" ]; then
  echo "✗ Service not found: $SERVICE on $CLUSTER" >&2
  exit 1
fi

_extract() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$SVC_JSON" | jq -r --arg k "$key" '.[$k] // empty'
  else
    local py=python3
    command -v python3 >/dev/null 2>&1 || py=python
    printf '%s' "$SVC_JSON" | "$py" -c "import json,sys; d=json.load(sys.stdin); v=d.get(sys.argv[1]); print('' if v is None else v)" "$key"
  fi
}

TD_ARN=$(_extract taskDefinition)
DESIRED=$(_extract desiredCount)
DESIRED="${DESIRED:-0}"
echo "  current desiredCount=$DESIRED taskDefinition=$TD_ARN"

TD_JSON=$(aws ecs describe-task-definition --task-definition "$TD_ARN" \
  --query 'taskDefinition' --output json)

NEED_LOCATION=0
case "$SERVICE" in
  *-order|*-social) NEED_LOCATION=1 ;;
esac

patch_td() {
  local py=python3
  command -v python3 >/dev/null 2>&1 || py=python
  "$py" -c '
import json, sys

img, service, need_loc, region, place, route, provider, mem, cpu = sys.argv[1:10]
td = json.load(sys.stdin)
c0 = td["containerDefinitions"][0]
c0["image"] = img

if mem:
    td["memory"] = str(mem)
if cpu:
    td["cpu"] = str(cpu)

if need_loc == "1":
    env = c0.get("environment") or []
    by_name = {e["name"]: e for e in env if "name" in e}
    for k, v in {
        "AwsLocation__Region": region,
        "AwsLocation__PlaceIndexName": place,
    }.items():
        by_name[k] = {"name": k, "value": v}
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
' "$IMAGE" "$SERVICE" "$NEED_LOCATION" "$LOC_REGION" "$LOC_PLACE" "$LOC_ROUTE" "$LOC_PROVIDER" \
  "${TASK_MEMORY}" "${TASK_CPU}"
}

NEW_TD=$(printf '%s' "$TD_JSON" | patch_td)

NEW_ARN=$(aws ecs register-task-definition --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)
echo "  registered $NEW_ARN${TASK_MEMORY:+ (memory=$TASK_MEMORY)}${TASK_CPU:+ (cpu=$TASK_CPU)}"

UPDATE_ARGS=(
  --cluster "$CLUSTER"
  --service "$SERVICE"
  --task-definition "$NEW_ARN"
  --force-new-deployment
)

# Unpark rules:
# - MIN_DESIRED + current desired > 0 → raise if below min (service already on)
# - MIN_DESIRED + desired 0 → only if FORCE_UNPARK=1 (avoid sucking capacity for workers)
# - desired 0 + no force → update TD only (image ready when later scaled)
if [ -n "$MIN_DESIRED" ]; then
  if [ "$DESIRED" -gt 0 ] && [ "$DESIRED" -lt "$MIN_DESIRED" ]; then
    echo "  desiredCount $DESIRED < ECS_MIN_DESIRED=$MIN_DESIRED — scaling up"
    UPDATE_ARGS+=(--desired-count "$MIN_DESIRED")
  elif [ "$DESIRED" -eq 0 ] && [ "$FORCE_UNPARK" = "1" ]; then
    echo "  ECS_FORCE_UNPARK=1 — scaling 0 → $MIN_DESIRED"
    UPDATE_ARGS+=(--desired-count "$MIN_DESIRED")
  elif [ "$DESIRED" -eq 0 ]; then
    echo "  desiredCount=0 (parked) — image registered, NOT unparking (set ECS_FORCE_UNPARK=1 to start)"
  fi
fi

aws ecs update-service "${UPDATE_ARGS[@]}" >/dev/null

# Parked: no wait needed
if [ "${DESIRED}" = "0" ] && [ "$FORCE_UNPARK" != "1" ] && { [ -z "$MIN_DESIRED" ] || true; }; then
  # only skip wait when we did NOT scale up
  FINAL_D=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query 'services[0].desiredCount' --output text)
  if [ "${FINAL_D:-0}" = "0" ]; then
    echo "✓ $SERVICE task-def updated (parked desired=0) image registered"
    exit 0
  fi
fi

echo "  waiting services-stable ..."
if ! aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE"; then
  echo "✗ wait services-stable failed" >&2
  aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,events:events[0:5]}' \
    --output json >&2 || true

  # Surface RESOURCE:MEMORY / crash reasons from recent stopped tasks
  STOPPED=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" \
    --desired-status STOPPED --max-items 3 --query 'taskArns' --output text 2>/dev/null || true)
  if [ -n "${STOPPED//None/}" ] && [ -n "$STOPPED" ]; then
    echo "  recent stopped tasks:" >&2
    aws ecs describe-tasks --cluster "$CLUSTER" --tasks $STOPPED \
      --query 'tasks[].{stop:stoppedReason,code:stopCode}' --output table >&2 || true
  fi
  echo "  Hint: TaskFailedToStart RESOURCE:MEMORY → cluster full (raise ASG max or park workers)." >&2
  exit 1
fi

ROLL_STATE=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].deployments[?status==`PRIMARY`]|[0].rolloutState' --output text)
echo "  primary rolloutState=$ROLL_STATE"
if [ "$ROLL_STATE" = "FAILED" ]; then
  echo "✗ Deploy failed: rolloutState=FAILED" >&2
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
echo "✓ $SERVICE deployed"
