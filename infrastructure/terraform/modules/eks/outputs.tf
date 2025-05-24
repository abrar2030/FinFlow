output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_eks_cluster.main.vpc_config[0].security_group_ids
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = var.create_cluster_role ? aws_iam_role.cluster[0].name : "external-role"
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = var.create_cluster_role ? aws_iam_role.cluster[0].arn : "external-role-arn"
}

output "node_groups" {
  description = "Map of EKS node groups created"
  value       = aws_eks_node_group.main
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = "*.${aws_eks_cluster.main.name}.elb.${data.aws_region.current.name}.amazonaws.com"
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = data.aws_elb_hosted_zone_id.main.id
}

# Data sources for outputs
data "aws_region" "current" {}

data "aws_elb_hosted_zone_id" "main" {}
