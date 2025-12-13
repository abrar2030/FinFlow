# Terraform Provider Configuration

terraform {
  required_version = ">= 1.5.0"

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# KMS Key for encryption
resource "aws_kms_key" "finflow_key" {
  description             = "KMS key for Finflow application encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/s3.amazonaws.com/AWSServiceRoleForS3",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/secretsmanager.amazonaws.com/AWSServiceRoleForSecretsManager",
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "finflow-kms-key-${var.environment}"
  })
}

resource "aws_kms_alias" "finflow_key_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.finflow_key.key_id
}

# Secrets Manager Module
module "secrets_manager" {
  source      = "./modules/secrets_manager"
  prefix      = var.secrets_manager_prefix
  kms_key_id  = aws_kms_key.finflow_key.key_id
  environment = var.environment
  tags        = var.tags
}
