locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== VPC =====
resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11: VPC Flow Logs omitted for cost optimization
  #checkov:skip=CKV2_AWS_12: Default security group managed separately

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ===== Internet Gateway =====
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ===== Public Subnets =====
#checkov:skip=CKV_AWS_130: Public subnet intentionally assigns public IPs for ALB
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                             = "${local.name_prefix}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks" = "shared"
  }
}

# ===== Private Subnets =====
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                             = "${local.name_prefix}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks" = "shared"
  }
}

# ===== ELASTIC IPs cho NAT GATEWAYS =====
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===== NAT GATEWAYS (1 per AZ for High Availability) =====
resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===== PUBLIC ROUTE TABLE =====
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ===== PRIVATE ROUTE TABLES (1 per AZ, route qua NAT Gateway tương ứng) =====
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}