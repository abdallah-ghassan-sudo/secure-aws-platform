resource "aws_kms_key" "baseline_key" {
  description             = "Central KMS CMK for encrypting Audit Logs, CloudTrail, CloudWatch, and SNS"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # Production note: Terraform HCL forbids variable interpolation inside `lifecycle`.
  # In a real production workspace, uncomment the following line manually:
  # lifecycle { prevent_destroy = true }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrailEncryptLogs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      },
      {
        Sid    = "AllowCloudWatchLogsUseOfTheKey"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
      {
        # DEFENSE-IN-DEPTH STATEMENT (NOT STRICTLY REQUIRED):
        # In the CloudWatch Alarm → SNS → KMS call chain, SNS is the principal
        # calling KMS (covered by AllowSNSUseOfTheKey below). CloudWatch only
        # calls SNS, not KMS directly.
        # This statement is retained as defense-in-depth, strictly scoped by
        # aws:SourceArn and aws:SourceAccount, to future-proof against changes
        # in AWS's internal call chain and to satisfy strict auditors.
        Sid    = "AllowCloudWatchAlarmsDefenseInDepth"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
        }
      },
      {
        Sid    = "AllowSNSUseOfTheKey"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "sns.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "baseline_key_alias" {
  name          = "alias/${var.project_name}-cmk"
  target_key_id = aws_kms_key.baseline_key.key_id
}