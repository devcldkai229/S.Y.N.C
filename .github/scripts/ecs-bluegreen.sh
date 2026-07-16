#!/usr/bin/env bash
# Blue/Green deploy Gateway qua CodeDeploy (ECS).
# Yêu cầu Terraform tạo sẵn: CodeDeploy application + deployment group
#   app  = sync-<env>-<service>
#   dg   = sync-<env>-<service>-dg
# và ALB 2 target group (blue/green) + 2 listener (prod/test).
# Usage: ecs-bluegreen.sh <app-name e.g. sync-prod-gateway> <image>
set -euo pipefail

APP="$1"; IMAGE="$2"
CLUSTER="${ECS_CLUSTER_PROD:-${CLUSTER:-}}"
SERVICE="$APP"
DG="${APP}-dg"
CONTAINER_NAME="${CONTAINER_NAME:-app}"
CONTAINER_PORT="${CONTAINER_PORT:-8080}"

echo "→ Blue/Green deploy $APP with $IMAGE"

# 1) Đăng ký task-def revision mới (image mới)
TD_ARN=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)
NEW_TD=$(aws ecs describe-task-definition --task-definition "$TD_ARN" \
  --query 'taskDefinition' --output json \
  | jq --arg IMAGE "$IMAGE" '
      .containerDefinitions[0].image=$IMAGE
      | del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)')
NEW_ARN=$(aws ecs register-task-definition --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)
echo "  registered $NEW_ARN"

# 2) AppSpec cho CodeDeploy-ECS
APPSPEC=$(jq -nc --arg td "$NEW_ARN" --arg c "$CONTAINER_NAME" --argjson p "$CONTAINER_PORT" '
  {version:0.0,
   Resources:[{TargetService:{Type:"AWS::ECS::Service",
     Properties:{TaskDefinition:$td,
       LoadBalancerInfo:{ContainerName:$c,ContainerPort:$p}}}}]}')

# 3) Tạo deployment blue/green
DEP_ID=$(aws deploy create-deployment \
  --application-name "$APP" \
  --deployment-group-name "$DG" \
  --revision "revisionType=AppSpecContent,appSpecContent={content='$(echo "$APPSPEC" | sed "s/'/'\\\\''/g")'}" \
  --query 'deploymentId' --output text)
echo "  deployment: $DEP_ID"

echo "  waiting deployment-successful ..."
aws deploy wait deployment-successful --deployment-id "$DEP_ID"
echo "✓ $APP blue/green deployed (tự rollback nếu health/hook fail)"
