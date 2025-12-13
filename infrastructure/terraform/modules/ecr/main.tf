locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Create ECR repositories
resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)

  name                 = "finflow-${var.environment}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_scan_on_push
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(
    {
      Name = "finflow-${var.environment}-${each.key}"
    },
    local.common_tags
  )
}

# Create lifecycle policy for each repository
resource "aws_ecr_lifecycle_policy" "main" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Create repository policy for each repository
resource "aws_ecr_repository_policy" "main" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
