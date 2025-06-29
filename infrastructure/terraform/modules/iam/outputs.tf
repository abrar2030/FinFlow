output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "rds_role_arn" {
  description = "ARN of the RDS IAM role"
  value       = aws_iam_role.rds_role.arn
}

output "secrets_manager_access_role_arn" {
  description = "ARN of the Secrets Manager access IAM role"
  value       = aws_iam_role.secrets_manager_access_role.arn
}


