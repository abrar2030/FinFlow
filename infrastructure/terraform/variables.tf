# Variables for Terraform configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "finflow-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type        = map(any)
  default     = {
    app_nodes = {
      name           = "app-nodes"
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 3
      disk_size      = 50
      labels = {
        role = "app"
      }
    },
    db_nodes = {
      name           = "db-nodes"
      instance_types = ["r5.large"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      disk_size      = 100
      labels = {
        role = "database"
      }
    },
    monitoring_nodes = {
      name           = "monitoring-nodes"
      instance_types = ["t3.large"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      disk_size      = 80
      labels = {
        role = "monitoring"
      }
    }
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instances in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "finflow.example.com"
}

variable "enable_bastion" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
