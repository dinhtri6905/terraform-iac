locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# S3 BUCKET: TERRAFORM STATE
# - Tạo một lần duy nhất
# - KHÔNG được destroy cùng terraform-infra
# - Giữ prevent_destroy = true để tránh xóa nhầm
######
# ============================================================
resource "aws_s3_bucket" "tfstate" {
  #checkov:skip=CKV2_AWS_62: Event notifications not required for Terraform state bucket
  #checkov:skip=CKV_AWS_144: Cross-region replication not required in lab environment
  #checkov:skip=CKV_AWS_18: Access logging omitted for cost optimization in lab environment

  bucket = var.tfstate_bucket_name

  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name    = var.tfstate_bucket_name
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  #checkov:skip=CKV_AWS_300: Terraform state bucket does not require multipart upload cleanup

  bucket     = aws_s3_bucket.tfstate.id
  depends_on = [aws_s3_bucket_versioning.tfstate]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
###########
# ============================================================
# DYNAMODB TABLE: STATE LOCKING
# - Ngăn concurrent apply
# - KHÔNG được destroy cùng terraform-infra
# ============================================================
# checkov:skip=CKV_AWS_28: Point-in-Time Recovery (PITR) is disabled to save storage costs.
# checkov:skip=CKV_AWS_119: Using AWS owned keys for DynamoDB to avoid KMS recurring charges.
resource "aws_dynamodb_table" "terraform_lock" {
  #checkov:skip=CKV_AWS_28: PITR not required for Terraform lock table
  #checkov:skip=CKV_AWS_119: AWS managed encryption is sufficient for Terraform lock table


  name         = var.dynamodb_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name    = var.dynamodb_lock_table_name
    Purpose = "terraform-state-lock"
  }
}
