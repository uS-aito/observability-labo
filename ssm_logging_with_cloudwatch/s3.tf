resource "aws_s3_bucket" "ssm_raw_logs" {
  bucket = "ssm-session-raw-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_raw_logs_lifecycle" {
  bucket = aws_s3_bucket.ssm_raw_logs.id

  # ルール1: 生データの自動削除と、不完全なアップロードのクリーンアップ
  rule {
    id     = "expire-raw-logs-and-cleanup-multipart"
    status = "Enabled"

    # バケット内のすべてのオブジェクトに適用
    filter {}

    # オブジェクトの有効期限（作成から何日後に削除するか）、現在の設定は14日
    expiration {
      days = 14
    }

    # 不完全なマルチパートアップロードの残骸を自動削除する（コスト削減のベストプラクティス）
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
