output "cluster_name" {
  description = "Tên EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_id" {
  description = "ID của EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "API server endpoint của EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_iam_role_arn" {
  description = "ARN của IAM role gán cho EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_arn" {
  description = "ARN của EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_iam_role_arn" {
  description = "ARN của IAM role gán cho worker nodes"
  value       = aws_iam_role.eks_nodes.arn
}

output "cluster_oidc_issuer" {
  description = "OIDC issuer URL (dùng cho IRSA)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN của OIDC Provider (dùng cho IRSA)"
  value       = aws_iam_openid_connect_provider.eks.arn
}
