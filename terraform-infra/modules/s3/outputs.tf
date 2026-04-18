output "config_bucket_name" {
  value = aws_s3_bucket.config.bucket
}

output "config_bucket_arn" {
  value = aws_s3_bucket.config.arn
}

output "static_bucket_name" {
  value = aws_s3_bucket.static.bucket
}

output "static_bucket_arn" {
  value = aws_s3_bucket.static.arn
}
