output "repository_urls" {
  description = "Map tên repo → ECR URL (dùng để docker push/pull)"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map tên repo → ARN"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.arn
  }
}

output "repository_names" {
  description = "Map tên repo → tên đầy đủ trên ECR"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.name
  }
}

output "registry_id" {
  description = "AWS Account ID của ECR registry"
  value       = data.aws_caller_identity.current.account_id
}
