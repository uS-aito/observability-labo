resource "aws_cloudwatch_log_group" "ssm_session_logs" {
  name              = "/aws/ssm/session-manager-logs"
  retention_in_days = 90 # ログの保持期間（日）
}

resource "aws_cloudwatch_log_subscription_filter" "ssm_logs_filter" {
  name            = "ssm-logs-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.ssm_session_logs.name
  filter_pattern  = "" # 空文字にすることで、すべてのログレコードを転送対象にする
  destination_arn = aws_kinesis_firehose_delivery_stream.ssm_logs_stream.arn
  role_arn        = aws_iam_role.cwl_to_firehose_role.arn
}

resource "aws_ssm_document" "session_manager_prefs" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = false
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_session_logs.name
      cloudWatchEncryptionEnabled = false
      cloudWatchStreamingEnabled  = true
      idleSessionTimeout          = "20"
      maxSessionDuration          = ""
      kmsKeyId                    = ""
      runAsEnabled                = false
      runAsDefaultUser            = ""
      shellProfile = {
        windows = ""
        linux   = ""
      }
    }
  })
}