module "vpc" {
  source = "./modules/vpc"

  vpc_name            = "${var.cluster_name}-vpc"
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  environment         = var.environment
  
  # Additional VPC settings
  enable_nat_gateway  = true
  single_nat_gateway  = false
  enable_vpn_gateway  = false
  
  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Tags
  tags = merge(var.tags, {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  node_groups     = var.node_groups
  environment     = var.environment
  
  # IAM settings
  create_cluster_role = true
  
  # Networking
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  # Tags
  tags = var.tags
}

module "rds" {
  source = "./modules/rds"

  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.database_subnets
  environment           = var.environment
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_engine_version     = var.db_engine_version
  
  # Database instances
  databases = {
    auth = {
      name = "auth"
      port = 5432
    },
    payments = {
      name = "payments"
      port = 5432
    },
    accounting = {
      name = "accounting"
      port = 5432
    },
    analytics = {
      name = "analytics"
      port = 5432
    }
  }
  
  # Security
  create_security_group = true
  allowed_cidr_blocks   = [var.vpc_cidr]
  
  # Tags
  tags = var.tags
}

module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
  
  # Repository names
  repositories = [
    "frontend",
    "api-gateway",
    "auth-service",
    "payments-service",
    "accounting-service",
    "analytics-service",
    "credit-engine"
  ]
  
  # Image scanning and lifecycle policies
  enable_scan_on_push = true
  image_retention_count = 10
  
  # Tags
  tags = var.tags
}

module "route53" {
  source = "./modules/route53"

  domain_name = var.domain_name
  environment = var.environment
  
  # Record sets
  record_sets = {
    main = {
      name = ""
      type = "A"
      alias = {
        name                   = module.eks.load_balancer_hostname
        zone_id                = module.eks.load_balancer_zone_id
        evaluate_target_health = true
      }
    },
    api = {
      name = "api"
      type = "A"
      alias = {
        name                   = module.eks.load_balancer_hostname
        zone_id                = module.eks.load_balancer_zone_id
        evaluate_target_health = true
      }
    }
  }
  
  # Tags
  tags = var.tags
}

module "bastion" {
  source = "./modules/bastion"
  count  = var.enable_bastion ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnets[0]
  environment       = var.environment
  ssh_key_name      = "finflow-${var.environment}"
  allowed_cidr      = ["0.0.0.0/0"]  # Should be restricted in production
  
  # Tags
  tags = var.tags
}

# Create namespaces in Kubernetes
resource "kubernetes_namespace" "finflow" {
  metadata {
    name = "finflow-${var.environment}"
    
    labels = {
      name        = "finflow-${var.environment}"
      environment = var.environment
    }
  }
  
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    
    labels = {
      name        = "monitoring"
      environment = var.environment
    }
  }
  
  depends_on = [module.eks]
}

# Install Prometheus and Grafana using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "45.7.1"
  
  values = [
    file("${path.module}/helm-values/prometheus-values.yaml")
  ]
  
  depends_on = [kubernetes_namespace.monitoring]
}

# Output important information
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "The URLs of the ECR repositories"
  value       = module.ecr.repository_urls
}

output "bastion_public_ip" {
  description = "The public IP of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].public_ip : null
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
