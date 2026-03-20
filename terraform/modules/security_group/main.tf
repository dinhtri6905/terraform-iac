locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# SECURITY GROUP: EKS CLUSTER CONTROL PLANE
# Quản lý traffic vào/ra API server của EKS
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-eks-cluster-sg"
  description = "Security Group cho EKS cluster control plane"
  vpc_id      = var.vpc_id  # nhận từ variable, không tham chiếu trực tiếp

  # Worker nodes gọi lên API server qua port 443
  ingress {
    description     = "Worker nodes to control plane API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # Control plane giao tiếp nội bộ
  ingress {
    description = "Control plane self communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-eks-cluster-sg"
  }
}

# SECURITY GROUP: EKS WORKER NODES
# Quản lý traffic vào/ra các EC2 node instances
resource "aws_security_group" "eks_nodes" {
  name        = "${local.name_prefix}-eks-nodes-sg"
  description = "Security Group cho EKS worker nodes"
  vpc_id      = var.vpc_id

  # Nodes giao tiếp với nhau (pod-to-pod, CNI)
  ingress {
    description = "Node to node — all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Control plane gửi lệnh xuống nodes (kubelet, kube-proxy)
  ingress {
    description     = "Control plane to nodes — ephemeral ports"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Control plane gọi kubelet API trên nodes
  ingress {
    description     = "Control plane to nodes — kubelet API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # ALB/ELB forward traffic vào NodePort của pods
  ingress {
    description     = "ALB to nodes — NodePort range"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound — nodes cần ra internet để pull image, gọi AWS API"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-eks-nodes-sg"
  }
}

# SECURITY GROUP: APPLICATION LOAD BALANCER (ELB)
# Nhận traffic từ internet, forward vào nodes
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security Group cho Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP từ internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS từ internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "ALB forward traffic tới worker nodes"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "" {

# }

# resource "aws_vpc_security_group_egress_rule" "" {
  
# }