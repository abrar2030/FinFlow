resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(
    {
      Name        = "${var.environment}-finflow-vpc"
      Environment = var.environment
    },
    var.tags
  )
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    {
      Name        = "${var.environment}-public-subnet-${count.index}"
      Environment = var.environment
      "kubernetes.io/role/elb" = "1"
    },
    var.tags
  )
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      Name        = "${var.environment}-private-subnet-${count.index}"
      Environment = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.tags
  )
}

# Database subnets
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.database_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      Name        = "${var.environment}-database-subnet-${count.index}"
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
      Name        = "${var.environment}-finflow-igw"
      Environment = var.environment
    },
    var.tags
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)
  
  domain = "vpc"
  
  tags = merge(
    {
      Name        = "${var.environment}-nat-eip-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(
    {
      Name        = "${var.environment}-nat-gw-${count.index}"
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
      Name        = "${var.environment}-public-rt"
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
  count = length(var.public_subnet_cidrs)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.environment}-private-rt-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# Routes to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnet_cidrs)
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route tables for database subnets
resource "aws_route_table" "database" {
  count = length(var.database_subnet_cidrs)
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.environment}-database-rt-${count.index}"
      Environment = var.environment
    },
    var.tags
  )
}

# Routes to NAT Gateway for database subnets
resource "aws_route" "database_nat_gateway" {
  count = length(var.database_subnet_cidrs)
  
  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Route table associations for database subnets
resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# Security Group for Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-alb-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "Allow traffic to EKS nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb.id, aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-eks-nodes-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for RDS Databases
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Allow traffic to RDS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432 # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-rds-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "${var.environment}-bastion-sg"
  description = "Allow SSH access to Bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to known IPs in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-bastion-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Network ACL for Public Subnets
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = merge(
    {
      Name        = "${var.environment}-public-nacl"
      Environment = var.environment
    },
    var.tags
  )
}

# Network ACL for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = merge(
    {
      Name        = "${var.environment}-private-nacl"
      Environment = var.environment
    },
    var.tags
  )
}

# Network ACL for Database Subnets
resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 5432 # PostgreSQL
    to_port    = 5432
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 5432
    to_port    = 5432
    cidr_block = aws_vpc.main.cidr_block
    action     = "allow"
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = merge(
    {
      Name        = "${var.environment}-database-nacl"
      Environment = var.environment
    },
    var.tags
  )
}

# VPN Gateway (optional)
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.environment}-finflow-vpn-gw"
      Environment = var.environment
    },
    var.tags
  )
}


