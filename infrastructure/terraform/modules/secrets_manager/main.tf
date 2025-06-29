resource "aws_secretsmanager_secret" "finflow_secret" {
  name_prefix = "${var.prefix}${var.environment}/"
  description = "Finflow application secret"
  kms_key_id  = var.kms_key_id

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "finflow_secret_version" {
  secret_id     = aws_secretsmanager_secret.finflow_secret.id
  secret_string = "{}" # Placeholder, actual secrets will be managed outside Terraform
}


