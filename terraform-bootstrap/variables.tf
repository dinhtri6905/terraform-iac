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

variable "tfstate_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state (unique toàn cầu)"
  type        = string
  default     = "iac-dev-tfstate-548"
}

variable "dynamodb_lock_table_name" {
  description = "Tên DynamoDB table dùng cho Terraform state locking"
  type        = string
  default     = "iac-dev-tf-lock"
}
