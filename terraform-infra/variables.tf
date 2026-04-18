# ===== GENERAL =====
variable "project_name" {
  description = "Tên project, dùng làm prefix cho resource"
  type        = string
  default     = "iac"
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region triển khai"
  type        = string
  default     = "ap-southeast-1"
}

# ===== VPC =====
variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Danh sách Availability Zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks cho Public Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks cho Private Subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# ===== EKS =====
variable "eks_cluster_version" {
  description = "Phiên bản Kubernetes cho EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type cho EKS worker nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "eks_node_min_size" {
  description = "Số node tối thiểu trong Auto Scaling Group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Số node tối đa trong Auto Scaling Group"
  type        = number
  default     = 3
}

variable "eks_node_desired_size" {
  description = "Số node mong muốn trong Auto Scaling Group"
  type        = number
  default     = 2
}

variable "eks_node_disk_size" {
  description = "Dung lượng ổ đĩa (GB) cho mỗi worker node"
  type        = number
  default     = 20
}

# ===== ECR =====
variable "ecr_repositories" {
  description = "Danh sách tên ECR repository cần tạo"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "ecr_image_retention_count" {
  description = "Số lượng image tối đa giữ lại mỗi repo"
  type        = number
  default     = 10
}

# ===== S3 APPLICATION BUCKETS =====
variable "config_bucket_name" {
  description = "Tên S3 bucket lưu config files (unique toàn cầu)"
  type        = string
  default     = "iac-dev-config"
}

variable "static_bucket_name" {
  description = "Tên S3 bucket lưu static files (unique toàn cầu)"
  type        = string
  default     = "iac-dev-static"
}
