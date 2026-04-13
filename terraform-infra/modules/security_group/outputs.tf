output "eks_cluster_sg_id" {
  description = "Security Group ID của EKS control plane"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_sg_id" {
  description = "Security Group ID của EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "alb_sg_id" {
  description = "Security Group ID của ALB"
  value       = aws_security_group.alb.id
}
