# ===== VPC OUTPUTS =====
output "vpc_id" {
  description = "ID của VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block của VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs của các Public Subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs của các Private Subnets"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs của các NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# ===== EKS OUTPUTS =====
output "eks_cluster_name" {
  description = "Tên EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API endpoint của EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data của EKS cluster"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "eks_node_group_arn" {
  description = "ARN của EKS Node Group"
  value       = module.eks.node_group_arn
}

output "eks_oidc_provider_arn" {
  description = "ARN của OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# ===== ECR OUTPUTS =====
output "ecr_repository_urls" {
  description = "Map tên repo → ECR URL"
  value       = module.ecr.repository_urls
}

output "ecr_registry_id" {
  description = "AWS Account ID của ECR registry"
  value       = module.ecr.registry_id
}


# ===== S3 OUTPUTS =====
output "s3_tfstate_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state"
  value       = module.s3.tfstate_bucket_name
}

output "s3_config_bucket_name" {
  description = "Tên S3 bucket lưu config files"
  value       = module.s3.config_bucket_name
}

output "s3_static_bucket_name" {
  description = "Tên S3 bucket lưu static files"
  value       = module.s3.static_bucket_name
}

output "dynamodb_lock_table_name" {
  description = "Tên DynamoDB table dùng cho state locking"
  value       = module.s3.dynamodb_lock_table_name
}


# ===== SECURITY GROUP OUTPUTS =====
output "eks_cluster_sg_id" {
  description = "Security Group ID của EKS cluster"
  value       = module.security_group.eks_cluster_sg_id
}

output "eks_nodes_sg_id" {
  description = "Security Group ID của EKS worker nodes"
  value       = module.security_group.eks_nodes_sg_id
}
