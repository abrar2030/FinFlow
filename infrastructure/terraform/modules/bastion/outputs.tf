output "instance_id" {
  description = "The ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "The public IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "private_ip" {
  description = "The private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "The ID of the security group for the bastion host"
  value       = aws_security_group.bastion.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for the bastion host"
  value       = aws_iam_role.bastion.arn
}

output "ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
}
