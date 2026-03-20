terraform {
  backend "s3" {
    bucket         = "iac-dev-tfstate"  
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

# ============================================================
# HƯỚNG DẪN SỬ DỤNG BACKEND
# ============================================================
#
# Backend có vấn đề "chicken-and-egg":
# bucket phải tồn tại TRƯỚC khi Terraform dùng nó làm backend.
#
# Thứ tự deploy đúng:
#
# BƯỚC 1 — Comment toàn bộ block backend "s3" {} ở trên
#           Terraform sẽ dùng local backend (lưu state tại máy)
#
# BƯỚC 2 — Tạo S3 bucket và DynamoDB table trước
#   terraform init
#   terraform apply -target=module.s3
#
# BƯỚC 3 — Uncomment block backend "s3" {} ở trên
#           Sau đó migrate state lên S3
#   terraform init -migrate-state
#
# BƯỚC 4 — Apply toàn bộ hạ tầng còn lại
#   terraform apply
#
# ============================================================
