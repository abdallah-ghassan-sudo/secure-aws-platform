output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.main.id
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "audit_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail audit logs"
  value       = aws_s3_bucket.audit_logs.id
}

output "kms_key_arn" {
  description = "ARN of the Customer Managed KMS Key"
  value       = aws_kms_key.baseline_key.arn
}

output "cloudtrail_arn" {
  description = "ARN of the baseline CloudTrail"
  value       = aws_cloudtrail.main_trail.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group receiving real-time CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail_logs.name
}

output "security_alerts_sns_arn" {
  description = "ARN of the SNS Topic broadcasting security metric alarms"
  value       = aws_sns_topic.security_alerts.arn
}