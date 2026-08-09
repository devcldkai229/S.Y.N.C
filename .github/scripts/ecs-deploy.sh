#!/usr/bin/env bash
# Rolling deploy: đăng ký task-def revision mới với image mới rồi update service.
# Usage: ecs-deploy.sh <cluster> <service> <image>
# Nếu 1 command trong pipepline thất bại, cả pipeline sẽ xem là thất bại
set -euo pipefail

CLUSTER="$1"; SERVICE="$2"; IMAGE="$3"

echo "→ Rolling deploy $SERVICE on $CLUSTER with $IMAGE"

# Task-def hiện tại của service
TD_ARN=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)

# Lấy JSON task-def, thay image container đầu tiên, bỏ field read-only
NEW_TD=$(aws ecs describe-task-definition --task-definition "$TD_ARN" \
  --query 'taskDefinition' --output json \
  | jq --arg IMAGE "$IMAGE" '
      .containerDefinitions[0].image = $IMAGE
      | del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
    ')

# Đăng ký revision mới
NEW_ARN=$(aws ecs register-task-definition --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)
echo "  registered $NEW_ARN"

# Update service (rolling; circuit breaker + rollback bật ở service config qua Terraform)
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$NEW_ARN" >/dev/null

echo "  waiting services-stable ..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE"

# Tránh "xanh giả": circuit breaker rollback → service vẫn stable trên task CŨ
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

echo "✓ $SERVICE deployed"
