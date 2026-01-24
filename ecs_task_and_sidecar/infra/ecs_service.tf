resource "aws_security_group" "ecs_sg" {
  name        = "${local.prefix}-sg"
  description = "Allow outbound traffic for ECS tasks"
  vpc_id      = aws_vpc.main.id

  # アウトバウンド: 全許可 (ECR Pull, CloudWatch Logs, OTel送信のため必須)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg" }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  # Container Insightsを有効化 (本番同様のメトリクス監視のため)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "main" {
  name            = "${local.prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn # 前回のコードで作成したタスク定義を参照
  desired_count   = 1
  launch_type     = "FARGATE"

  # ネットワーク設定
  network_configuration {
    subnets          = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # NAT Gatewayがないため、Public IPを持たせてインターネットへ出る
  }

  # タスク定義が更新されたら、自動的に新しいタスクをデプロイする設定
  force_new_deployment = true
}
