```
# 変数設定 (app_repository_url output)
OTEL_REPO_URL="438465126106.dkr.ecr.ap-northeast-1.amazonaws.com/otel-collector"

# ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $OTEL_REPO_URL

# ビルド (もしまだなら)
docker build --platform linux/amd64 -t otel-collector .

# タグ付け
docker tag otel-collector:latest ${OTEL_REPO_URL}:latest

# プッシュ
docker push ${OTEL_REPO_URL}:latest
```