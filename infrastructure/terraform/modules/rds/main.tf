locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Security group for RDS instances
resource "aws_security_group" "rds" {
  count = var.create_security_group ? 1 : 0
  
  name        = "finflow-${var.environment}-rds-sg"
  description = "Security group for FinFlow RDS instances"
  vpc_id      = var.vpc_id
  
  # PostgreSQL access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "PostgreSQL access"
  }
  
  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(
    {
      Name = "finflow-${var.environment}-rds-sg"
    },
    local.common_tags
  )
}

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name        = "finflow-${var.environment}-subnet-group"
  description = "Subnet group for FinFlow RDS instances"
  subnet_ids  = var.subnet_ids
  
  tags = merge(
    {
      Name = "finflow-${var.environment}-subnet-group"
    },
    local.common_tags
  )
}

# DB parameter group
resource "aws_db_parameter_group" "postgres" {
  name        = "finflow-${var.environment}-postgres-params"
  family      = "postgres${replace(var.db_engine_version, ".", "")}"
  description = "Parameter group for FinFlow PostgreSQL instances"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  
  parameter {
    name  = "max_connections"
    value = "100"
  }
  
  tags = merge(
    {
      Name = "finflow-${var.environment}-postgres-params"
    },
    local.common_tags
  )
}

# RDS instances
resource "aws_db_instance" "main" {
  for_each = var.databases
  
  identifier           = "finflow-${var.environment}-${each.value.name}"
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true
  
  db_name              = each.value.name
  username             = "postgres"
  password             = random_password.db_password[each.key].result
  port                 = each.value.port
  
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.rds[0].id] : []
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.postgres.name
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  
  multi_az               = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "finflow-${var.environment}-${each.value.name}-final"
  deletion_protection    = true
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  tags = merge(
    {
      Name = "finflow-${var.environment}-${each.value.name}"
    },
    local.common_tags
  )
}

# Generate random passwords for RDS instances
resource "random_password" "db_password" {
  for_each = var.databases
  
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store passwords in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  for_each = var.databases
  
  name        = "finflow/${var.environment}/db/${each.value.name}"
  description = "Credentials for FinFlow ${each.value.name} database"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  for_each = var.databases
  
  secret_id = aws_secretsmanager_secret.db_credentials[each.key].id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db_password[each.key].result
    engine   = "postgres"
    host     = aws_db_instance.main[each.key].address
    port     = aws_db_instance.main[each.key].port
    dbname   = each.value.name
    url      = "postgresql://postgres:${random_password.db_password[each.key].result}@${aws_db_instance.main[each.key].address}:${aws_db_instance.main[each.key].port}/${each.value.name}"
  })
}
