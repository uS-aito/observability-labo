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