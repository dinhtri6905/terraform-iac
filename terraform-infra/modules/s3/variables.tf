variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "config_bucket_name" {
  description = "Tên S3 bucket lưu config files (unique toàn cầu)"
  type        = string
}

variable "static_bucket_name" {
  description = "Tên S3 bucket lưu static files (unique toàn cầu)"
  type        = string
}
