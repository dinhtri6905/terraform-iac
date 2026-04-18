# Mô hình
1. AWS Network: 1 VPC, 3 Availability Zones, 3 Public subnets, 3 Private subnets, Security Group, Internet Gateway, NAT Gateway

2. EKS: Amazon EKS, Auto Scaling Group, Kubernetes ELB(route traffic vào EKS), nodes(1→3)

3. ECR: lưu trữ và quản lý Docker image

4. S3: dành cho các file (tfstate, configure file, static file,...)


<!-- 
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
#   terraform apply -target module.s3
#
# BƯỚC 3 — Uncomment block backend "s3" {} ở trên
#           Sau đó migrate state lên S3
#   terraform init -migrate-state
#
# BƯỚC 4 — Apply toàn bộ hạ tầng còn lại
#   terraform apply
#
# ============================================================ 
-->

## Thứ tự destroy an toàn
``` bash
# Bước 1 — Xem trước những gì sẽ bị xóa
terraform plan -destroy

# Bước 2 — Destroy toàn bộ
terraform destroy
```

## Nếu chỉ muốn destroy 1 module cụ thể
``` bash
# Chỉ xóa EKS (tốn tiền nhất)
terraform destroy -target module.eks

# Chỉ xóa VPC
terraform destroy -target module.vpc

# Chỉ xóa S3
terraform destroy -target module.s3
```

Yêu cầu:
1. Tách hệ thống Terraform thành 2 project riêng biệt:
   * Project 1: "terraform-bootstrap"
     * Chỉ dùng để tạo S3 bucket (tfstate) và DynamoDB table (lock)
     * Chạy một lần duy nhất, không bị destroy cùng hệ thống chính
   * Project 2: "terraform-infra"
     * Dùng để triển khai hạ tầng chính (EKS, VPC, EC2, ECR, Security Group…)
     * Sử dụng backend S3 đã tạo từ bootstrap

2. Trong terraform-infra:
   * Chỉ cấu hình backend "s3"
   * KHÔNG được tạo lại S3 bucket hoặc DynamoDB table
   * Sử dụng module hóa (modules: vpc, eks, ecr, security_group…)

3. Thiết kế flow làm việc:
   * Khởi tạo backend (bootstrap)
   * Deploy infrastructure (infra)
   * Destroy infrastructure an toàn (không ảnh hưởng backend)
   * Destroy backend đúng cách (migrate state về local trước khi destroy)

4. Giải thích rõ:
   * Vì sao không được tạo backend trong cùng project
   * Vì sao destroy backend trực tiếp sẽ gây lỗi
   * Cách xử lý state lock khi bị kẹt

5. Đưa ra:
   * Cấu trúc thư mục chuẩn
   * Ví dụ code backend.tf
   * Ví dụ code bootstrap
   * Best practices (versioning, multi-env, CI/CD)

Mục tiêu:
Tạo một hệ thống Terraform production-ready, tránh lỗi:
* BucketAlreadyOwnedByYou
* State lock
* Destroy thất bại
* Mất state



# Bước 1 — Bootstrap: Tạo S3 + DynamoDB (chạy 1 lần)
```bash
cd terraform-bootstrap

terraform init

# Xem sẽ tạo gì
terraform plan

# Tạo S3 bucket tfstate + DynamoDB lock
terraform apply
```
Sau bước này bạn có:
- S3 bucket: iac-dev-tfstate-548 với versioning + SSE-KMS + prevent_destroy
- DynamoDB: iac-dev-tf-lock với prevent_destroy
- State của bootstrap nằm ở terraform-bootstrap/terraform.tfstate (local)
   +@@ Giữ file terraform.tfstate của bootstrap lại, đừng xóa. @@

# Bước 2 — Deploy Infrastructure
```bash
cd ../terraform-infra

terraform init

terraform plan

terraform apply
```
Sau bước này bạn có:
- VPC + 3 Public Subnets + 3 Private Subnets + NAT Gateways
- Security Groups cho EKS cluster + worker nodes
- EKS Cluster iac-dev-eks + Node Group + OIDC Provider
- ECR repositories: iac-dev-backend, iac-dev-frontend
- S3 buckets: iac-dev-config, iac-dev-static

# Bước 3 — Kết nối kubectl
```bash
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name iac-dev-eks

kubectl get nodes
```

# Bước 4 — Import nếu bucket đã tồn tại
Nếu iac-dev-config hoặc iac-dev-static đã có trước đó:
```bash
# Mở terraform-infra/import.tf, uncomment block cần import:
# import {
#   to = module.s3.aws_s3_bucket.config
#   id = "iac-dev-config"
# }

terraform plan    # xem import plan
terraform apply   # thực hiện import

# Comment lại import.tf sau khi xong
```

# Bước 5 — Destroy Infrastructure (an toàn)
```bash
cd terraform-infra

terraform destroy
```
- S3 tfstate và DynamoDB lock vẫn còn nguyên. Bootstrap không bị ảnh hưởng.

# Bước 6 — Destroy Bootstrap (chỉ khi muốn xóa hoàn toàn)
```bash
cd terraform-bootstrap
# 1. Tạm comment prevent_destroy trong main.tf:
#    aws_s3_bucket.tfstate       → comment lifecycle { prevent_destroy = true }
#    aws_dynamodb_table.lock     → comment lifecycle { prevent_destroy = true }

# 2. Apply để cập nhật
terraform apply

# 3. Xóa hết objects trong S3 (bucket phải empty mới delete được)
aws s3 rm s3://iac-dev-tfstate-548 --recursive

# 4. Xóa tất cả versions (do versioning đang enabled)
aws s3api list-object-versions \
  --bucket iac-dev-tfstate-548 \
  --query 'Versions[].[Key,VersionId]' \
  --output text | while read KEY VER; do
    aws s3api delete-object \
      --bucket iac-dev-tfstate-548 \
      --key "$KEY" \
      --version-id "$VER"
  done

# 5. Destroy bootstrap
terraform destroy
```

## Xử lý State Lock bị kẹt
```bash
# Lấy Lock ID từ error message khi plan/apply bị interrupt
# Error: Error acquiring the state lock
# Lock ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Đảm bảo không còn tiến trình Terraform nào đang chạy
ps aux | grep terraform

# Force unlock
cd terraform-infra
terraform force-unlock <LOCK_ID>

# Nếu vẫn kẹt → xóa trực tiếp trong DynamoDB
aws dynamodb delete-item \
  --table-name iac-dev-tf-lock \
  --key '{"LockID":{"S":"iac-dev-tfstate-548/infra/dev/terraform.tfstate"}}'
```