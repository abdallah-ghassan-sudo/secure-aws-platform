resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.project_name}-trail"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.baseline_key.arn
}

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.project_name}-security-alerts"
  kms_master_key_id = aws_kms_key.baseline_key.arn
}

# Explicit resource policy: without this, SNS silently rejects cloudwatch.amazonaws.com
# publish attempts with AuthorizationError (a "silent failure" that terraform validate won't catch)
resource "aws_sns_topic_policy" "security_alerts_policy" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.security_alerts.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main_trail" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.baseline_key.arn

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]

  # Architectural note: sns_topic_name intentionally omitted to prevent
  # alert fatigue from S3 log-delivery notifications. SNS is triggered
  # exclusively by CloudWatch Metric Alarms on critical events (see alerts.tf).
}