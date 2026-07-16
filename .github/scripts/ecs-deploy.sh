#!/usr/bin/env bash
# Rolling deploy: đăng ký task-def revision mới với image mới rồi update service.
# Usage: ecs-deploy.sh <cluster> <service> <image>
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
echo "✓ $SERVICE deployed"
