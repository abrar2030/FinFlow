locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Name        = "finflow-${var.environment}-bastion"
    },
    var.tags
  )
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion" {
  name        = "finflow-${var.environment}-bastion-sg"
  description = "Security group for FinFlow bastion host"
  vpc_id      = var.vpc_id
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
    description = "SSH access"
  }
  
  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = local.common_tags
}

# IAM role for bastion host
resource "aws_iam_role" "bastion" {
  name = "finflow-${var.environment}-bastion-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# IAM instance profile for bastion host
resource "aws_iam_instance_profile" "bastion" {
  name = "finflow-${var.environment}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# Attach SSM policy to bastion role for session management
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion.name
}

# Bastion host EC2 instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Install Docker
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    
    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    
    # Install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    
    # Set up SSH hardening
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    systemctl restart sshd
  EOF
  
  tags = local.common_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for bastion host
resource "aws_eip" "bastion" {
  domain = "vpc"
  
  tags = local.common_tags
}

# Associate Elastic IP with bastion host
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}
