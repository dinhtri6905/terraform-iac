# ============================================================
# IMPORT: Các S3 bucket application đã tồn tại trước khi dùng Terraform
#
# Cách dùng:
#   1. Uncomment block cần import
#   2. terraform plan   → kiểm tra import plan
#   3. terraform apply  → thực hiện import
#   4. Comment lại sau khi import thành công
# ============================================================

# import {
#   to = module.s3.aws_s3_bucket.config
#   id = "iac-dev-config"
# }

# import {
#   to = module.s3.aws_s3_bucket.static
#   id = "iac-dev-static"
# }
