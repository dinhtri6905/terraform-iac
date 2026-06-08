locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== CONFIG BUCKET =====
resource "aws_s3_bucket" "config" {
  #checkov:skip=CKV2_AWS_61: Lifecycle policy not required for configuration bucket
  #checkov:skip=CKV2_AWS_61: Lifecycle policy not required for configuration bucket
  #checkov:skip=CKV2_AWS_62: Event notifications not required
  #checkov:skip=CKV_AWS_145: SSE-S3 encryption is sufficient
  #checkov:skip=CKV_AWS_144: Cross-region replication not required
  #checkov:skip=CKV_AWS_18: Access logging omitted for cost optimization

  bucket = var.config_bucket_name

  tags = {
    Name    = var.config_bucket_name
    Purpose = "config"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===== STATIC BUCKET =====
#checkov:skip=CKV_AWS_18: Access logging omitted for cost optimization
#checkov:skip=CKV2_AWS_62: Event notifications not required 
#checkov:skip=CKV_AWS_144: Cross-region replication not required
#checkov:skip=CKV_AWS_145: SSE-S3 encryption is sufficient
resource "aws_s3_bucket" "static" {
  bucket = var.static_bucket_name

  tags = {
    Name    = var.static_bucket_name
    Purpose = "static-files"
  }
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "static" {
  #checkov:skip=CKV_AWS_300: Multipart upload cleanup not required for static bucket

  bucket = aws_s3_bucket.static.id

  rule {
    id     = "transition-old-files"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
