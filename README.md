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
