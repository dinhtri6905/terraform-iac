locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# S3 BUCKET: TERRAFORM STATE
# Lưu terraform.tfstate — cần tạo trước khi enable backend
# ============================================================
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name

  # Ngăn xóa nhầm bucket đang chứa state
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name    = var.tfstate_bucket_name
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled" # Bật versioning để rollback state khi cần
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# DYNAMODB TABLE: TERRAFORM STATE LOCKING
# Ngăn nhiều người chạy terraform apply cùng lúc
# ============================================================
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = var.dynamodb_lock_table
    Purpose = "terraform-state-lock"
  }
}

# ============================================================
# S3 BUCKET: CONFIG FILES
# Lưu application config, environment files, ...
# ============================================================
resource "aws_s3_bucket" "config" {
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
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# S3 BUCKET: STATIC FILES
# Lưu assets tĩnh: images, CSS, JS, ...
# ============================================================
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
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: tự động chuyển storage class để tiết kiệm chi phí
resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "transition-old-files"
    status = "Enabled"

    filter {} # apply cho tất cả objects trong bucket

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # Ít truy cập sau 30 ngày
    }

    transition {
      days          = 90
      storage_class = "GLACIER" # Lưu trữ lạnh sau 90 ngày
    }
  }
}
