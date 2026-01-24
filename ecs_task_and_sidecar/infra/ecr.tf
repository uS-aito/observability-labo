resource "aws_ecr_repository" "log_test_app" {
  name                 = "log-test-app"
  image_tag_mutability = "MUTABLE" # テスト用なので上書き可能に設定

  # プッシュ時の脆弱性スキャンを有効化（推奨）
  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true # terraform destroy時に中身ごと削除できるようにする
}

resource "aws_ecr_repository" "custom_fluentbit" {
  name                 = "custom-fluentbit"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "otel-collector" {
  name                 = "otel-collector"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# イメージが無制限に増えないよう、最新の10個だけ残して古いのを削除する設定
resource "aws_ecr_lifecycle_policy" "log_test_app_policy" {
  repository = aws_ecr_repository.log_test_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "custom_fluentbit_policy" {
  repository = aws_ecr_repository.custom_fluentbit.name

  policy = jsonencode({
    rules = [{
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = { 
          tagStatus = "any", 
          countType = "imageCountMoreThan", 
          countNumber = 10 
        }
        action = { 
          type = "expire" 
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "otel-collector_policy" {
  repository = aws_ecr_repository.otel-collector.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

