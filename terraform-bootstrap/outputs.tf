output "tfstate_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_bucket_arn" {
  description = "ARN của S3 bucket lưu Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "dynamodb_lock_table_name" {
  description = "Tên DynamoDB table dùng cho state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_lock_table_arn" {
  description = "ARN của DynamoDB table"
  value       = aws_dynamodb_table.terraform_lock.arn
}

# Gợi ý nội dung cho terraform-infra/backend.tf
output "backend_config_hint" {
  description = "Copy giá trị này vào terraform-infra/backend.tf"
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.tfstate.bucket}"
    key            = "infra/dev/terraform.tfstate"
    region         = "${aws_s3_bucket.tfstate.region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
    encrypt        = true
  EOT
}
