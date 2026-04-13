variable "project_name" {
  description = "Tên project, dùng làm prefix cho resource"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (dev / staging / prod)"
  type        = string
}

variable "repositories" {
  description = "Danh sách tên repositories cần tạo (vd: [\"backend\", \"frontend\"])"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "image_retention_count" {
  description = "Số lượng tagged image tối đa được giữ lại mỗi repo"
  type        = number
  default     = 10
}

variable "eks_node_role_arn" {
  description = "ARN của IAM Role gán cho EKS worker nodes — dùng để cấp quyền pull image"
  type        = string
}
