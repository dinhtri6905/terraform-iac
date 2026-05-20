locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== MODULE: VPC =====
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ===== MODULE: SECURITY GROUP =====
module "security_group" {
  source = "./modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ===== MODULE: EKS =====
module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  cluster_version        = var.eks_cluster_version
  private_subnet_ids     = module.vpc.private_subnet_ids
  cluster_sg_id          = module.security_group.eks_cluster_sg_id
  node_security_group_id = module.security_group.eks_nodes_sg_id
  node_instance_type     = var.eks_node_instance_type
  node_min_size          = var.eks_node_min_size
  node_max_size          = var.eks_node_max_size
  node_desired_size      = var.eks_node_desired_size
  node_disk_size         = var.eks_node_disk_size
}

# ===== MODULE: ECR =====
module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  environment           = var.environment
  repositories          = var.ecr_repositories
  image_retention_count = var.ecr_image_retention_count
  eks_node_role_arn     = module.eks.node_group_iam_role_arn
}

# ===== MODULE: S3 (Application Buckets) =====
# Đây là config/static bucket cho ứng dụng
# KHÔNG phải tfstate bucket — tfstate được quản lý bởi terraform-bootstrap
module "s3" {
  source = "./modules/s3"

  project_name       = var.project_name
  environment        = var.environment
  config_bucket_name = var.config_bucket_name
  static_bucket_name = var.static_bucket_name
}



# # ===== MODULE: CLOUDTRAIL =====
# module "cloudtrail" {
#   source = "./modules/cloudtrail"

#   project_name         = var.project_name
#   environment          = var.environment
# }

# # ===== MODULE: CLOUDWATCH =====
# module "cloudwatch" {
#   source = "./modules/cloudwatch-alarms"

#   project_name         = var.project_name
#   environment          = var.environment

# }