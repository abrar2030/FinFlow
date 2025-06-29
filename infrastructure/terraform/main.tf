# Terraform Provider Configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  backend "s3" {
    bucket         = "finflow-terraform-state"
    key            = "global/s3/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "finflow-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "FinFlow"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# VPC Module
module "vpc" {
  source  = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones = var.availability_zones
  environment = var.environment
  tags = var.tags
}

# KMS Key for encryption
resource "aws_kms_key" "finflow_key" {
  description             = "KMS key for Finflow application encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow use of the key"
        Effect    = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/s3.amazonaws.com/AWSServiceRoleForS3",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/secretsmanager.amazonaws.com/AWSServiceRoleForSecretsManager",
            # Add other roles that need to use this key
          ]
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "finflow_key_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.finflow_key.key_id
}

# Secrets Manager Module
module "secrets_manager" {
  source  = "./modules/secrets_manager"
  prefix = var.secrets_manager_prefix
  kms_key_id = aws_kms_key.finflow_key.key_id
  environment = var.environment
  tags = var.tags
}

# IAM Module
module "iam" {
  source  = "./modules/iam"
  environment = var.environment
  tags = var.tags
  aws_region = var.aws_region
  secrets_manager_prefix = var.secrets_manager_prefix
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
}

# EKS Module
module "eks" {
  source  = "./modules/eks"
  cluster_name = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_groups = var.node_groups
  environment = var.environment
  tags = var.tags
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_group_role_arn = module.iam.eks_node_group_role_arn
}

# CloudWatch Logging Module
module "cloudwatch_logging" {
  source  = "./modules/cloudwatch_logging"
  environment = var.environment
  s3_bucket_name = "finflow-cloudtrail-logs-${var.environment}"
  tags = var.tags
}

data "aws_caller_identity" "current" {}


