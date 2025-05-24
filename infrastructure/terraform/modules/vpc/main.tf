resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  
  tags = merge(
    {
      Name        = var.vpc_name
      Environment = var.environment
    },
    var.tags
  )
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-public-${var.availability_zones[count.index]}"
      Environment = var.environment
      "kubernetes.io/role/elb" = "1"
    },
    var.tags
  )
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-private-${var.availability_zones[count.index]}"
      Environment = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.tags
  )
}

# Database subnets
resource "aws_subnet" "database" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2*length(var.availability_zones))
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-database-${var.availability_zones[count.index]}"
      Environment = var.environment
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  domain = "vpc"
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-nat-eip-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-nat-gw-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
  
  depends_on = [aws_internet_gateway.main]
}

# Route tables for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-public-rt"
      Environment = var.environment
    },
    var.tags
  )
}

# Route to Internet Gateway for public subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-private-rt-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# Routes to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# Route tables for database subnets
resource "aws_route_table" "database" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-database-rt-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# Routes to NAT Gateway for database subnets
resource "aws_route" "database_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  
  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Route table associations for database subnets
resource "aws_route_table_association" "database" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[var.single_nat_gateway ? 0 : count.index].id
}

# VPN Gateway (optional)
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.vpc_name}-vpn-gw"
      Environment = var.environment
    },
    var.tags
  )
}
