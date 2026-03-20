output "vpc_id" {
  description = "ID của VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block của VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Danh sách ID của Public Subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Danh sách ID của Private Subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "Danh sách ID của NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = aws_internet_gateway.main.id
}
