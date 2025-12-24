## VPC & Subnet
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {Name = "${var.project_name}-vpc"}
}

# Public Subnet for Bastion Host/NAT Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {Name = "${var.project_name}-public-subnet"}
}

# Private Subnet for RDS/Redshift
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a" # AZ a
  tags = {Name = "${var.project_name}-private-subnet-a"}
}
resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_2_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}b" # AZ b (คนละ AZ)
  tags = {Name = "${var.project_name}-private-subnet-b"}
}


## Internet Gateway
# IGW for Public
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {Name = "${var.project_name}-igw"}
}

# EIP
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {Name = "${var.project_name}-nat-eip"}
}

# NAT Gateway for Private
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id # NAT Gateway in Public Subnet
  depends_on    = [aws_internet_gateway.igw]
  tags = {Name = "${var.project_name}-nat-gw"}
}


## Route Table
# Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # เส้นทางไปสู่อินเทอร์เน็ต
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {Name = "${var.project_name}-public-rt"}
}

# Connect to Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0" # เส้นทางไปสู่อินเทอร์เน็ต
    nat_gateway_id = aws_nat_gateway.nat.id # แต่ให้ออกทาง NAT
  }
  tags = {Name = "${var.project_name}-private-rt"}
}

# Connect to Private Subnet 1 and 2
resource "aws_route_table_association" "private_1" { # เชื่อม Private Subnet 1
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_2" { # เชื่อม Private Subnet 2
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}