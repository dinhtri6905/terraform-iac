variable "project_name" {
  description = "Tên project" // dùng làm prefix cho resource
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (dev / staging / prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC — nhận từ module vpc"
  type        = string
}
