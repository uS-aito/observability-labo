locals {
  app_image = "${aws_ecr_repository.log_test_app.repository_url}:latest"
  fluentbit_image = "${aws_ecr_repository.custom_fluentbit.repository_url}:latest"

  prefix    = "firelens-otel-test"
}

# ---------------------------------------------
# IAM Role (Task Execution Role)
# ---------------------------------------------
resource "aws_iam_role" "execution_role" {
  name = "${local.prefix}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------
# Log Groups
# ---------------------------------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${local.prefix}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "firelens_logs" {
  name              = "/ecs/${local.prefix}/firelens-container"
  retention_in_days = 7
}

# ---------------------------------------------
# ECS Task Definition
# ---------------------------------------------
resource "aws_ecs_task_definition" "main" {
  family                   = "${local.prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    # 1. Application
    {
      name      = "app"
      image     = local.app_image
      essential = true
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name              = "cloudwatch_logs"
          region            = "ap-northeast-1"
          log_group_name    = aws_cloudwatch_log_group.app_logs.name
          log_stream_prefix = "app"
          auto_create_group = "true"
        }
      }
    },

    # 2. FireLens (カスタムイメージに変更 & fileタイプに変更)
    {
      name      = "firelens"
      image     = aws_ecr_repository.custom_fluentbit.repository_url
      essential = true
      
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "config-file-type"  = "file"
          "config-file-value" = "/fluent-bit/etc/extra.conf"
        }
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.firelens_logs.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "firelens"
        }
      }
    },
    {
      name      = "otel-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = true
      command   = ["--config=/etc/ecs/ecs-default-config.yaml"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.firelens_logs.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "otel"
        }
      }
    }
  ])
}