variable "project_name" {
  description = "Tên project" // dùng làm prefix cho resource
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (dev / staging / prod)"
  type        = string
}

variable "cluster_version" {
  description = "Phiên bản Kubernetes cho EKS cluster"
  type        = string
  default     = "1.31"
}

variable "private_subnet_ids" {
  description = "IDs của Private Subnets — nơi worker nodes chạy"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "Security Group ID của EKS control plane"
  type        = string
}

variable "node_security_group_id" {
  description = "Security Group ID của worker nodes"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type cho worker nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "node_min_size" {
  description = "Số node tối thiểu trong Auto Scaling Group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Số node tối đa trong Auto Scaling Group"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Số node mong muốn trong Auto Scaling Group"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Dung lượng ổ đĩa (GB) cho mỗi worker node"
  type        = number
  default     = 20
}
