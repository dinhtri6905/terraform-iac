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

## Push lên GitHub
- Thêm file lock vào git (nên commit để đồng bộ version provider với team)
git add .terraform.lock.hcl

- Commit các thay đổi code (backend.tf đã comment, ...)
git add backend.tf
git add .

git commit -m "feat: init terraform project"

git push origin main


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