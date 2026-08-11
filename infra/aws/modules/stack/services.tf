# 13 service qua module ecs-service. Naming sync-<env>-<svc> khớp app-cicd.yml.
# Nội bộ gọi nhau bằng Service Connect DNS: http://<alias>:<port>.

locals {
  tag = var.image_tag

  # Cross-service URLs (.NET đọc key `XService:BaseUrl` → env `XService__BaseUrl`)
  sc_urls = {
    IamService__BaseUrl          = "http://iam:8080"
    RoadmapService__BaseUrl      = "http://roadmap:8080"
    ExerciseService__BaseUrl     = "http://exercise:8080"
    NutritionService__BaseUrl    = "http://nutrition:8080"
    MarketplaceService__BaseUrl  = "http://marketplace:8080"
    OrderService__BaseUrl        = "http://order:8080"
    PaymentService__BaseUrl      = "http://payment:8080"
    NotificationService__BaseUrl = "http://notification:8080"
    SocialService__BaseUrl       = "http://social:8080"
  }

  dotnet_common_env = merge(local.sc_urls, {
    ASPNETCORE_ENVIRONMENT = "Production"
    ASPNETCORE_URLS        = "http://+:8080"
    AWS__Region            = var.region
    Jwt__Issuer            = var.jwt_issuer
    Jwt__Audience          = var.jwt_audience
    # Shared S3 buckets — tách env bằng key prefix (dev/… vs prod/…)
    Storage__Bucket        = module.s3_cdn.public_bucket
    Storage__KeyPrefix     = "${var.env}/"
    Storage__PublicBaseUrl = local.media_public_base_url
  })

  # Gateway YARP: override destination sang Service Connect DNS
  # (key destination trong appsettings là "<svc>/primary")
  gateway_dest_env = merge(
    { for s in ["iam", "roadmap", "exercise", "nutrition", "marketplace", "order", "payment", "notification", "social"] :
      "ReverseProxy__Clusters__${s}-cluster__Destinations__${s}/primary__Address" => "http://${s}:8080"
    },
    {
      "ReverseProxy__Clusters__ai-cluster__Destinations__ai/primary__Address"   = "http://ai:8088"
      "ReverseProxy__Clusters__rcm-cluster__Destinations__rcm/primary__Address" = "http://rcm:8000"
    },
  )

  sec   = module.secrets.secret_arns
  param = module.secrets.param_arns

  # DB connection parts (app tự ghép ConnectionStrings qua composer). Tất cả inject
  # qua task-def `secrets[]` (valueFrom): host/port/user ← SSM ARN, password ← Secrets
  # Manager ARN. ECS resolve cả hai loại ARN như nhau khi khởi tạo task.
  dotnet_pg_conn = {
    Db__Postgres__Host     = local.param["db/pg-host"]
    Db__Postgres__Port     = local.param["db/pg-port"]
    Db__Postgres__User     = local.param["db/pg-user"]
    Db__Postgres__Password = local.sec["db/postgres-password"]
  }
  dotnet_mongo_conn = {
    Db__Mongo__Host     = local.param["db/mongo-host"]
    Db__Mongo__User     = local.param["db/mongo-user"]
    Db__Mongo__Password = local.sec["db/mongo-password"]
  }

  dotnet_shared_secrets = {
    Jwt__SecretKey             = local.sec["shared/jwt-secret"]
    InternalApiKey             = local.sec["shared/internal-api-key"]
    IamService__InternalApiKey = local.sec["shared/internal-api-key"]
  }

  ai_base_urls = {
    IAM_BASE_URL          = "http://iam:8080"
    ROADMAP_BASE_URL      = "http://roadmap:8080"
    EXERCISE_BASE_URL     = "http://exercise:8080"
    NUTRITION_BASE_URL    = "http://nutrition:8080"
    MARKETPLACE_BASE_URL  = "http://marketplace:8080"
    ORDER_BASE_URL        = "http://order:8080"
    PAYMENT_BASE_URL      = "http://payment:8080"
    NOTIFICATION_BASE_URL = "http://notification:8080"
    SOCIAL_BASE_URL       = "http://social:8080"
  }

  ai_env = merge(local.ai_base_urls, {
    ENVIRONMENT      = "production"
    REDIS_URL        = "redis://${module.redis.endpoint}:6379/2"
    JWT_ISSUER       = var.jwt_issuer
    JWT_AUDIENCE     = var.jwt_audience
    AI_SQS_QUEUE_URL = module.sqs.queue_url
    # Python tự ghép POSTGRES_DSN từ các phần này + DB_POSTGRES_PASSWORD
    DB_POSTGRES_NAME = "sync_ai"
  })

  ai_secrets = {
    DB_POSTGRES_HOST     = local.param["db/pg-host"]
    DB_POSTGRES_PORT     = local.param["db/pg-port"]
    DB_POSTGRES_USER     = local.param["db/pg-user"]
    DB_POSTGRES_PASSWORD = local.sec["db/postgres-password"]
    INTERNAL_API_KEY     = local.sec["shared/internal-api-key"]
    JWT_SIGNING_KEY      = local.sec["shared/jwt-secret"]
    OPENAI_API_KEY       = local.sec["llm/openai-api-key"]
    TAVILY_API_KEY       = local.sec["llm/tavily-api-key"]
    # Optional observability — set LANGFUSE_ENABLED=true after putting real keys
    LANGFUSE_PUBLIC_KEY = local.param["ai/langfuse-public-key"]
    LANGFUSE_SECRET_KEY = local.sec["ai/langfuse-secret-key"]
  }

  services = {
    gateway = {
      image_repo = "gateway"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 448
      env        = merge(local.dotnet_common_env, local.gateway_dest_env)
      secrets    = local.dotnet_shared_secrets
      public     = true
      command    = null
    }
    iam = {
      image_repo = "iam"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 640
      env = merge(local.dotnet_common_env, {
        Db__Postgres__Name         = "sync_iam"
        Email__VerificationBaseUrl = local.api_base_url
      })
      secrets = merge(local.dotnet_shared_secrets, local.dotnet_pg_conn, {
        Email__Brevo__UserName = local.param["mail/brevo-username"]
        Email__Brevo__Password = local.sec["mail/brevo-password"]
        # Google Sign-In audiences (comma-separated IDs OK via ClientId legacy merge,
        # or put the primary Web client ID). Also map array index 0 for multi-binding.
        GoogleAuth__ClientId     = local.param["auth/google-client-ids"]
        GoogleAuth__ClientIds__0 = local.param["auth/google-client-ids"]
      })
      public  = false
      command = null
    }
    roadmap = {
      image_repo = "roadmap"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env        = merge(local.dotnet_common_env, { Db__Mongo__Name = "sync_roadmap" })
      secrets    = merge(local.dotnet_shared_secrets, local.dotnet_mongo_conn)
      public     = false
      command    = null
    }
    exercise = {
      image_repo = "exercise"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env        = merge(local.dotnet_common_env, { Db__Mongo__Name = "sync_exercise" })
      secrets    = merge(local.dotnet_shared_secrets, local.dotnet_mongo_conn)
      public     = false
      command    = null
    }
    nutrition = {
      image_repo = "nutrition"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env        = merge(local.dotnet_common_env, { Db__Mongo__Name = "sync_nutrition" })
      secrets    = merge(local.dotnet_shared_secrets, local.dotnet_mongo_conn)
      public     = false
      command    = null
    }
    marketplace = {
      image_repo = "marketplace"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env        = merge(local.dotnet_common_env, { Db__Mongo__Name = "sync_marketplace" })
      secrets    = merge(local.dotnet_shared_secrets, local.dotnet_mongo_conn)
      public     = false
      command    = null
    }
    order = {
      image_repo = "order"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env = merge(local.dotnet_common_env, {
        Db__Postgres__Name           = "sync_order"
        ConnectionStrings__Redis     = "${module.redis.endpoint}:6379"
        # AWS Location Place Index — reverse geocode + address search (Sync Foods)
        AwsLocation__Region          = var.region
        AwsLocation__PlaceIndexName  = var.aws_location_place_index_name
      })
      secrets = merge(local.dotnet_shared_secrets, local.dotnet_pg_conn, {
        Ahamove__ApiKey = local.sec["delivery/ahamove-api-key"]
        Ahamove__Mobile = local.param["delivery/ahamove-mobile"]
      })
      public  = false
      command = null
    }
    payment = {
      image_repo = "payment"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env        = merge(local.dotnet_common_env, { Db__Postgres__Name = "sync_payment" })
      secrets = merge(local.dotnet_shared_secrets, local.dotnet_pg_conn, {
        PayOS__ClientId    = local.sec["pay/payos-client-id"]
        PayOS__ApiKey      = local.sec["pay/payos-api-key"]
        PayOS__ChecksumKey = local.sec["pay/payos-checksum-key"]
      })
      public  = false
      command = null
    }
    notification = {
      image_repo = "notification"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env = merge(local.dotnet_common_env, {
        Db__Postgres__Name = "sync_smartpush"
        Db__Mongo__Name    = "sync_notification"
      })
      secrets = merge(local.dotnet_shared_secrets, local.dotnet_pg_conn, local.dotnet_mongo_conn, {
        OpenAI__ApiKey = local.sec["llm/openai-api-key"]
      })
      public  = false
      command = null
    }
    social = {
      image_repo = "social"
      port       = 8080
      # Task-level CPU for EC2 must be ≥ 128 (AWS rejects 96 with Invalid 'cpu' setting).
      cpu        = 128
      memory     = 384
      env = merge(local.dotnet_common_env, {
        Db__Mongo__Name                  = "sync_social"
        # AWS Location route calculator — community challenge "Đường đi"
        AwsLocation__Region              = var.region
        AwsLocation__RouteCalculatorName = var.aws_location_route_calculator_name
        AwsLocation__DataProvider        = var.aws_location_data_provider
        AwsLocation__PlaceIndexName      = var.aws_location_place_index_name
      })
      secrets    = merge(local.dotnet_shared_secrets, local.dotnet_mongo_conn)
      public     = false
      command    = null
    }
    ai = {
      image_repo = "ai"
      port       = 8088
      cpu        = 192
      memory     = 640
      env        = local.ai_env
      secrets    = local.ai_secrets
      public     = false
      command    = null
    }
    ai-worker = {
      image_repo = "ai"
      port       = null # không listen — SQS consumer
      cpu        = 128
      memory     = 384
      env        = local.ai_env
      secrets    = local.ai_secrets
      public     = false
      command    = ["python", "-m", "app.events.consumer"]
    }
    rcm = {
      image_repo = "rcm"
      port       = 8000
      cpu        = 128
      memory     = 448 # OpenAI API embeddings — no local sentence-transformers
      env = {
        JWT_ISSUER             = var.jwt_issuer
        JWT_AUDIENCE           = var.jwt_audience
        OPENAI_BASE_URL        = "https://api.openai.com/v1"
        OPENAI_MODEL           = "gpt-4o-mini"
        OPENAI_EMBEDDING_MODEL = "text-embedding-3-small"
        EMBEDDING_DIM          = "1536"
        IAM_SERVICE_URL        = "http://iam:8080"
        EXERCISE_SERVICE_URL   = "http://exercise:8080"
        ROADMAP_SERVICE_URL    = "http://roadmap:8080"
        # App tự ghép DATABASE_URL (asyncpg) từ các phần này + DB_POSTGRES_PASSWORD
        DB_POSTGRES_NAME = "sync_ai_agent"
      }
      secrets = {
        DB_POSTGRES_HOST     = local.param["db/pg-host"]
        DB_POSTGRES_PORT     = local.param["db/pg-port"]
        DB_POSTGRES_USER     = local.param["db/pg-user"]
        DB_POSTGRES_PASSWORD = local.sec["db/postgres-password"]
        OPENAI_API_KEY       = local.sec["llm/openai-api-key"]
        JWT_SECRET_KEY       = local.sec["shared/jwt-secret"]
      }
      public  = false
      command = null
    }
  }
}

module "ecs_service" {
  source   = "../ecs-service"
  for_each = local.services

  name         = "${local.name}-${each.key}"
  cluster_arn  = module.ecs_cluster.cluster_arn
  cluster_name = module.ecs_cluster.cluster_name
  image        = "${var.ecr_repository_urls[each.value.image_repo]}:${local.tag}"

  cpu            = each.value.cpu
  memory         = each.value.memory
  container_port = each.value.port
  service_alias  = each.value.port != null ? each.key : null
  command        = each.value.command

  desired_count = contains(var.critical_services, each.key) ? var.desired_count_critical : 1
  autoscaling = each.value.port == null ? null : {
    min        = contains(var.critical_services, each.key) ? var.desired_count_critical : 1
    max        = 4
    cpu_target = 60
  }

  capacity_provider = contains(var.critical_services, each.key) ? module.ecs_cluster.capacity_provider_ondemand : module.ecs_cluster.capacity_provider_spot

  env     = each.value.env
  secrets = each.value.secrets

  task_role_arn      = module.iam_tasks.task_role_arn
  execution_role_arn = module.iam_tasks.task_execution_role_arn
  namespace_arn      = module.ecs_cluster.namespace_arn
  log_retention_days = var.log_retention_days
  region             = var.region

  # Gateway prod: CodeDeploy blue/green; còn lại rolling
  deployment_controller = each.key == "gateway" && var.enable_bluegreen ? "CODE_DEPLOY" : "ECS"
  target_group_arn      = each.value.public ? module.alb.target_group_blue_arn : null

  # Place Index / Route Calculator must exist before order/social tasks use them.
  depends_on = [
    aws_location_place_index.main,
    aws_location_route_calculator.main,
  ]
}
