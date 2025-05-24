output "repository_urls" {
  description = "The URLs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "repository_arns" {
  description = "The ARNs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

output "repository_names" {
  description = "The names of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.main : k => v.name }
}

output "repository_registry_ids" {
  description = "The registry IDs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.main : k => v.registry_id }
}
