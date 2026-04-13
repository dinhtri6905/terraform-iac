variable "project_name" {
  description = "Tên project, dùng làm prefix cho resource"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (dev / staging / prod)"
  type        = string
}

variable "tfstate_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state (phải unique toàn cầu)"
  type        = string
}

variable "config_bucket_name" {
  description = "Tên S3 bucket lưu config files (phải unique toàn cầu)"
  type        = string
}

variable "static_bucket_name" {
  description = "Tên S3 bucket lưu static files (phải unique toàn cầu)"
  type        = string
}

variable "dynamodb_lock_table" {
  description = "Tên DynamoDB table dùng cho Terraform state locking"
  type        = string
  default     = "terraform-lock"
}
