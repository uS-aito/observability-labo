# ベースイメージ
FROM python:3-slim

# 作業ディレクトリの設定
WORKDIR /app

# 標準出力のバッファリングを無効化（ログを即時出力させるため重要）
ENV PYTHONUNBUFFERED=1

# スクリプトをコンテナ内にコピー
COPY app.py .

# アプリケーションの実行
CMD ["python", "app.py"]
