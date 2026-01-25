```
# 変数設定(fluentbit_repository_url output)
FLUENT_REPO_URL="438465126106.dkr.ecr.ap-northeast-1.amazonaws.com/custom-fluentbit"

# ログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $FLUENT_REPO_URL

# ビルド (ファイル名を指定)
docker build --platform linux/amd64 -t custom-fluentbit .

# タグ付け
docker tag custom-fluentbit:latest ${FLUENT_REPO_URL}:latest

# プッシュ
docker push ${FLUENT_REPO_URL}:latest
```

# memo
aws ecs execute-command \
  --cluster firelens-otel-test-cluster \
  --task 83d74aaa7d864a21bb212ef78a0471be \
  --container app \
  --interactive \
  --command "/bin/sh"


aws ecs describe-tasks --cluster firelens-otel-test-cluster  --tasks 09b3789685174c5da367868e45ca24c9 --query 'tasks[].enableExecuteCommand' --output text

aws ecs update-service \
    --cluster firelens-otel-test-cluster \
    --service firelens-otel-test-service \
    --force-new-deployment
