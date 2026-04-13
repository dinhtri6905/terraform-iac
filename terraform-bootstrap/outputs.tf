output "tfstate_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_bucket_arn" {
  description = "ARN của S3 bucket lưu Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "config_bucket_name" {
  description = "Tên S3 bucket lưu config files"
  value       = aws_s3_bucket.config.bucket
}

output "config_bucket_arn" {
  description = "ARN của S3 bucket lưu config files"
  value       = aws_s3_bucket.config.arn
}

output "static_bucket_name" {
  description = "Tên S3 bucket lưu static files"
  value       = aws_s3_bucket.static.bucket
}

output "static_bucket_arn" {
  description = "ARN của S3 bucket lưu static files"
  value       = aws_s3_bucket.static.arn
}

output "dynamodb_lock_table_name" {
  description = "Tên DynamoDB table dùng cho state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}
