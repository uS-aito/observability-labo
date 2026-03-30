resource "aws_kinesis_firehose_delivery_stream" "ssm_logs_stream" {
  name        = "ssm-session-logs-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.ssm_raw_logs.arn
    
    # 後続のGlue処理を見据えたHive形式のS3プレフィックス（自動で日付フォルダが切られます）
    prefix              = "raw-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "error-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

    # バッファリング設定: 5MB または 300秒（5分）到達ごとにS3へファイル出力
    buffering_size     = 5
    buffering_interval = 300
  }
}