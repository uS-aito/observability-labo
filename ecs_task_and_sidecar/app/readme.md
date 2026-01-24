```
# 変数設定 (app_repository_url output)
APP_REPO_URL="438465126106.dkr.ecr.ap-northeast-1.amazonaws.com/log-test-app"

# ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $APP_REPO_URL

# ビルド (もしまだなら)
docker build --platform linux/amd64 -t log-test-app .

# タグ付け
docker tag log-test-app:latest ${APP_REPO_URL}:latest

# プッシュ
docker push ${APP_REPO_URL}:latest
```