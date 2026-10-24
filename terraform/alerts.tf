# =============================================================================
# Event-Based Detections (rare events, high signal)
# treat_missing_data = "notBreaching" so quiet days do NOT trigger false alarms
# =============================================================================

# 1. Critical IAM changes (user creation, policy attach, access key creation)
resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "${var.project_name}-iam-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ ($.eventSource = \"iam.amazonaws.com\") && (($.eventName = \"CreateUser\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"CreateAccessKey\")) }"

  metric_transformation {
    name      = "IAMChanges"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes_alarm" {
  alarm_name          = "${var.project_name}-iam-changes-alarm"
  alarm_description   = "Triggers when critical IAM user, policy attachment, or key creation events are detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.iam_changes.metric_transformation[0].name
  namespace           = "SecurityBaseline"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
}

# 2. CloudTrail tampering (StopLogging, DeleteTrail, UpdateTrail)
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_tampering" {
  name           = "${var.project_name}-cloudtrail-tampering"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ ($.eventSource = \"cloudtrail.amazonaws.com\") && (($.eventName = \"StopLogging\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"UpdateTrail\")) }"

  metric_transformation {
    name      = "CloudTrailTampering"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_tampering_alarm" {
  alarm_name          = "${var.project_name}-cloudtrail-tampering-alarm"
  alarm_description   = "Triggers immediately if someone attempts to stop, delete, or modify CloudTrail"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.cloudtrail_tampering.metric_transformation[0].name
  namespace           = "SecurityBaseline"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
}

# 3. Root account usage
resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project_name}-root-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootLogin"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "${var.project_name}-root-login-alarm"
  alarm_description   = "Triggers on any interactive or API activity performed by the AWS Root user"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.root_login.metric_transformation[0].name
  namespace           = "SecurityBaseline"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
}

# 4. Security Group modifications (all ingress/egress/create/delete/modify)
resource "aws_cloudwatch_log_metric_filter" "sg_changes" {
  name           = "${var.project_name}-sg-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ ($.eventSource = \"ec2.amazonaws.com\") && (($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") || ($.eventName = \"ModifySecurityGroupRules\")) }"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "sg_changes_alarm" {
  alarm_name          = "${var.project_name}-sg-changes-alarm"
  alarm_description   = "Triggers when inbound/outbound rules or Security Groups are created, modified, or deleted"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.sg_changes.metric_transformation[0].name
  namespace           = "SecurityBaseline"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
}

# =============================================================================
# Telemetry Blackout Detection (Heartbeat)
# Uses AWS-native IncomingLogEvents metric (more reliable than a custom
# metric filter, since it measures ALL ingested log bytes regardless of
# eventType — avoiding false positives on quiet days).
# treat_missing_data = "breaching" because absence of logs = incident.
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "cloudtrail_heartbeat_alarm" {
  alarm_name          = "${var.project_name}-cloudtrail-heartbeat-alarm"
  alarm_description   = "CRITICAL: CloudTrail stopped delivering events to CloudWatch. Possible telemetry blackout (tampered IAM role, disabled subscription, or StopLogging)."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2

  metric_name = "IncomingLogEvents"
  namespace   = "AWS/Logs"
  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.cloudtrail_logs.name
  }

  period             = 1800 # 30 min × 2 evaluation periods = 1 hour window
  statistic          = "Sum"
  threshold          = 1
  treat_missing_data = "breaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]
  ok_actions    = [aws_sns_topic.security_alerts.arn]
}

# =============================================================================
# Email Subscription (created only if alert_email is provided)
# =============================================================================

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}