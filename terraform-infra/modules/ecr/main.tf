locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Lấy AWS Account ID hiện tại — dùng trong policy
data "aws_caller_identity" "current" {}

# ============================================================
# ECR REPOSITORIES
# for_each tạo nhiều repo cùng lúc từ danh sách var.repositories
# ============================================================
# checkov:skip=CKV_AWS_136: Using AWS managed keys for ECR encryption to optimize academic project budget.
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = "MUTABLE"

  # Tự động scan image mỗi khi push — phát hiện CVE sớm
  image_scanning_configuration {
    scan_on_push = true
  }

  # Mã hóa image at-rest
  encryption_configuration {
    encryption_type = "AES256"
  }

  # Cho phép xóa repo dù vẫn còn image bên trong (tiện khi destroy)
  force_delete = true

  tags = {
    Name = "${local.name_prefix}-${each.key}"
  }
}

# ============================================================
# ECR LIFECYCLE POLICY
# Tự động dọn dẹp image cũ để tiết kiệm storage cost
# ============================================================
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(var.repositories)                # ✅ keys tĩnh từ variable — không phụ thuộc apply-time
  repository = aws_ecr_repository.this[each.key].name # each.key = "backend" / "frontend"

  depends_on = [aws_ecr_repository.this]

  policy = jsonencode({
    rules = [
      {
        # Rule 1: Giữ tối đa N tagged image (theo prefix "v")
        rulePriority = 1
        description  = "Giữ tối đa ${var.image_retention_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = { type = "expire" }
      },
      {
        # Rule 2: Xóa untagged image sau 45 ngày (image từ CI/CD chưa tag)
        rulePriority = 2
        description  = "Xóa untagged images sau 45 ngày"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 45
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ============================================================
# ECR REPOSITORY POLICY
# Cho phép EKS worker nodes pull image từ ECR
# ============================================================
resource "aws_ecr_repository_policy" "this" {
  for_each   = toset(var.repositories)                # keys tĩnh từ variable — không phụ thuộc apply-time
  repository = aws_ecr_repository.this[each.key].name # each.key = "backend" / "frontend"

  depends_on = [aws_ecr_repository.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesPull"
        Effect = "Allow"
        Principal = {
          AWS = var.eks_node_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowGetAuthToken"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "ecr:GetAuthorizationToken"
      }
    ]
  })
}
