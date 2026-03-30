# EC2インスタンスに付与するためのロール
resource "aws_iam_role" "example_role" {
  name = "example-role"

  # このロールにアタッチするポリシー（権限）を設定します
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# SSMを使うためのポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.example_role.name
}

# SSMを使うためのプロファイル
resource "aws_iam_instance_profile" "test_profile" {
  name = "ssm_test_profile"
  role = aws_iam_role.example_role.name
}

# SSMのコマンドをcloudwatch logsに送るためのポリシー
resource "aws_iam_policy" "ssm_cloudwatch_logs_policy" {
  name        = "SSMSessionManagerCloudWatchLogsPolicy"
  description = "Allow SSM Session Manager to put session logs to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_cloudwatch_logs_attachment" {
  policy_arn = aws_iam_policy.ssm_cloudwatch_logs_policy.arn
  role       = aws_iam_role.example_role.name
}

# firehoseがS3に書き込むために使うロールとポリシー
resource "aws_iam_role" "firehose_role" {
  name = "firehose-ssm-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "firehose-s3-policy"
  role = aws_iam_role.firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.ssm_raw_logs.arn,
          "${aws_s3_bucket.ssm_raw_logs.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch LogsからFirehoseにデータを送るためのロールとポリシー
resource "aws_iam_role" "cwl_to_firehose_role" {
  name = "cwl-to-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cwl_to_firehose_policy" {
  name = "cwl-to-firehose-policy"
  role = aws_iam_role.cwl_to_firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.ssm_logs_stream.arn
      }
    ]
  })
}
