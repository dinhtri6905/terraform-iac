# Mô hình
1. AWS Network: 1 VPC, 3 Availability Zones, 3 Public subnets, 3 Private subnets, Security Group, Internet Gateway, NAT Gateway

2. EKS: Amazon EKS, Auto Scaling Group, Kubernetes ELB(route traffic vào EKS), nodes(1→3)

3. ECR: lưu trữ và quản lý Docker image

4. S3: dành cho các file (tfstate, configure file, static file,...)
