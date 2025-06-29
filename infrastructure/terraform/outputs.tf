output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the EKS OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL of the EKS cluster OIDC issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.finflow_key.arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.secrets_manager.secret_arn
}


