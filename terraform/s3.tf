data "aws_caller_identity" "current" {}

# checkov:skip=CKV_AWS_18: Access logging disabled to save costs
# checkov:skip=CKV2_AWS_62: Event notifications not required for audit logs
resource "aws_s3_bucket" "audit_logs" {
  bucket_prefix = "secure-audit-logs-"
  force_destroy = true 
}

resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs_block" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}