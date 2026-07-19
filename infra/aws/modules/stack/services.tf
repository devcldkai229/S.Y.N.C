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
  })

  # Gateway YARP: override destination sang Service Connect DNS
  # (key destination trong appsettings là "<svc>/primary")
  gateway_dest_env = merge(
    { for s in ["iam", "roadmap", "exercise", "nutrition", "marketplace", "order", "payment", "notification", "social"] :
      "ReverseProxy__Clusters__${s}-cluster__Destinations__${s}/primary__Address" => "http://${s}:8080"
    },
    {
      "ReverseProxy__Clusters__ai-cluster__Destinations__ai/primary__Address"           = "http://ai:8088"
      "ReverseProxy__Clusters__aiagent-cluster__Destinations__aiagent/primary__Address" = "http://aiagent:8000"
    },
  )

  sec = module.secrets.secret_arns

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
    ENVIRONMENT  = "production"
    REDIS_URL    = "redis://${module.redis.endpoint}:6379/2"
    JWT_ISSUER   = var.jwt_issuer
    JWT_AUDIENCE = var.jwt_audience
  })

  ai_secrets = {
    POSTGRES_DSN     = local.sec["db/pg-ai-dsn"]
    AMQP_URL         = local.sec["mq/amqp-url"]
    INTERNAL_API_KEY = local.sec["shared/internal-api-key"]
    JWT_SIGNING_KEY  = local.sec["shared/jwt-secret"]
    OPENAI_API_KEY   = local.sec["llm/openai-api-key"]
    DEEPSEEK_API_KEY = local.sec["llm/deepseek-api-key"]
    TAVILY_API_KEY   = local.sec["llm/tavily-api-key"]
  }

  services = {
    gateway = {
      image_repo = "gateway"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = merge(local.dotnet_common_env, local.gateway_dest_env)
      secrets    = local.dotnet_shared_secrets
      public     = true
      command    = null
    }
    iam = {
      image_repo = "iam"
      port       = 8080
      cpu        = 256
      memory     = 640
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__IamDatabase = local.sec["db/pg-iam"]
        Email__Brevo__UserName         = local.sec["mail/brevo-username"]
        Email__Brevo__Password         = local.sec["mail/brevo-password"]
      })
      public  = false
      command = null
    }
    roadmap = {
      image_repo = "roadmap"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__RoadmapDatabase = local.sec["db/mongo-roadmap"]
      })
      public  = false
      command = null
    }
    exercise = {
      image_repo = "exercise"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__ExerciseDatabase = local.sec["db/mongo-exercise"]
      })
      public  = false
      command = null
    }
    nutrition = {
      image_repo = "nutrition"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__NutritionDatabase = local.sec["db/mongo-nutrition"]
      })
      public  = false
      command = null
    }
    marketplace = {
      image_repo = "marketplace"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__MarketplaceDatabase = local.sec["db/mongo-marketplace"]
      })
      public  = false
      command = null
    }
    order = {
      image_repo = "order"
      port       = 8080
      cpu        = 256
      memory     = 512
      env = merge(local.dotnet_common_env, {
        ConnectionStrings__Redis = "${module.redis.endpoint}:6379"
      })
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__OrderDatabase = local.sec["db/pg-order"]
        Ahamove__ApiKey                  = local.sec["delivery/ahamove-api-key"]
        Ahamove__Mobile                  = local.sec["delivery/ahamove-mobile"]
      })
      public  = false
      command = null
    }
    payment = {
      image_repo = "payment"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__PaymentDatabase = local.sec["db/pg-payment"]
        PayOS__ClientId                    = local.sec["pay/payos-client-id"]
        PayOS__ApiKey                      = local.sec["pay/payos-api-key"]
        PayOS__ChecksumKey                 = local.sec["pay/payos-checksum-key"]
      })
      public  = false
      command = null
    }
    notification = {
      image_repo = "notification"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__NotificationDatabase = local.sec["db/mongo-notification"]
        ConnectionStrings__SmartPushDatabase    = local.sec["db/pg-smartpush"]
        OpenAI__ApiKey                          = local.sec["llm/openai-api-key"]
      })
      public  = false
      command = null
    }
    social = {
      image_repo = "social"
      port       = 8080
      cpu        = 256
      memory     = 512
      env        = local.dotnet_common_env
      secrets = merge(local.dotnet_shared_secrets, {
        ConnectionStrings__SocialDatabase = local.sec["db/mongo-social"]
      })
      public  = false
      command = null
    }
    ai = {
      image_repo = "ai"
      port       = 8088
      cpu        = 384
      memory     = 768
      env        = local.ai_env
      secrets    = local.ai_secrets
      public     = false
      command    = null
    }
    ai-worker = {
      image_repo = "ai"
      port       = null # không listen — RabbitMQ consumer
      cpu        = 256
      memory     = 512
      env        = local.ai_env
      secrets    = local.ai_secrets
      public     = false
      command    = ["python", "-m", "app.events.consumer"]
    }
    aiagent = {
      image_repo = "aiagent"
      port       = 8000
      cpu        = 384
      memory     = 896 # sentence-transformers model in-process
      env = {
        JWT_ISSUER           = var.jwt_issuer
        JWT_AUDIENCE         = var.jwt_audience
        DEEPSEEK_BASE_URL    = "https://api.deepseek.com"
        DEEPSEEK_MODEL       = "deepseek-chat"
        HF_HUB_OFFLINE       = "1"
        TRANSFORMERS_OFFLINE = "1"
        IAM_SERVICE_URL      = "http://iam:8080"
        EXERCISE_SERVICE_URL = "http://exercise:8080"
        ROADMAP_SERVICE_URL  = "http://roadmap:8080"
      }
      secrets = {
        DATABASE_URL     = local.sec["db/pg-aiagent-dsn"]
        DEEPSEEK_API_KEY = local.sec["llm/deepseek-api-key"]
        JWT_SECRET_KEY   = local.sec["shared/jwt-secret"]
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
}
