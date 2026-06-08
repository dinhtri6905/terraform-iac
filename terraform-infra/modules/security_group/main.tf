locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# SECURITY GROUP: EKS CLUSTER CONTROL PLANE
# Tạo SG rỗng trước — rules được thêm bên dưới bằng
# aws_security_group_rule để tránh circular dependency
# ============================================================
resource "aws_security_group" "eks_cluster" {
  #checkov:skip=CKV2_AWS_5: Security group attached by downstream resources

  name        = "${local.name_prefix}-eks-cluster-sg"
  description = "Security Group cho EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-eks-cluster-sg"
  }
}

# ============================================================
# SECURITY GROUP: EKS WORKER NODES
# ============================================================
resource "aws_security_group" "eks_nodes" {
  #checkov:skip=CKV2_AWS_5: Security group attached by downstream resources

  name        = "${local.name_prefix}-eks-nodes-sg"
  description = "Security Group cho EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-eks-nodes-sg"
  }
}

# ============================================================
# SECURITY GROUP: ALB
# ============================================================
resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5: Security group attached by downstream resources

  name        = "${local.name_prefix}-alb-sg"
  description = "Security Group cho Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ============================================================
# RULES: EKS CLUSTER CONTROL PLANE
# ============================================================

# Worker nodes → control plane (API server)
resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  type                     = "ingress"
  description              = "Worker nodes to control plane API 443"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

# Control plane → tất cả outbound
resource "aws_security_group_rule" "cluster_egress_all" {
  #checkov:skip=CKV_AWS_382: Full outbound access required for EKS operation

  type              = "egress"
  description       = "Cluster allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ============================================================
# RULES: EKS WORKER NODES
# ============================================================

# Nodes giao tiếp với nhau (pod-to-pod, CNI)
resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  description       = "Node to node all traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

# Control plane → nodes (ephemeral ports)
resource "aws_security_group_rule" "nodes_ingress_cluster_ephemeral" {
  type                     = "ingress"
  description              = "Control plane to nodes ephemeral ports"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# Control plane → nodes (kubelet API)
resource "aws_security_group_rule" "nodes_ingress_cluster_443" {
  type                     = "ingress"
  description              = "Control plane to nodes kubelet API"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# ALB → nodes (NodePort range)
resource "aws_security_group_rule" "nodes_ingress_alb_nodeport" {
  type                     = "ingress"
  description              = "ALB to nodes NodePort range"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
}

# Nodes → tất cả outbound (pull image ECR, gọi AWS API)
resource "aws_security_group_rule" "nodes_egress_all" {
  #checkov:skip=CKV_AWS_382: Full outbound access required for worker nodes

  type              = "egress"
  description       = "Nodes allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ============================================================
# RULES: ALB
# ============================================================

# Internet → ALB (HTTP)
resource "aws_security_group_rule" "alb_ingress_http" {
  #checkov:skip=CKV_AWS_260: Public HTTP access required for internet-facing ALB

  type              = "ingress"
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Internet → ALB (HTTPS)
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB → nodes outbound
resource "aws_security_group_rule" "alb_egress_nodes" {
  type                     = "egress"
  description              = "ALB forward traffic to worker nodes"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_nodes.id
}
