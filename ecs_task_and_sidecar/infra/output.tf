# ---------------------------------------------
# Output
# ---------------------------------------------
# 作成後のリポジトリURLを表示
output "app_repository_url" {
  value = aws_ecr_repository.log_test_app.repository_url
}

output "fluentbit_repository_url" {
  value = aws_ecr_repository.custom_fluentbit.repository_url
}
