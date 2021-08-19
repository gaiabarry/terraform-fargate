resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.log_group
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "gaia-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}