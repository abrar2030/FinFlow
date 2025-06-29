resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-eks-cluster-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.environment}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-eks-node-group-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role" "rds_role" {
  name = "${var.environment}-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-rds-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_policy" "rds_enhanced_monitoring_policy" {
  name        = "${var.environment}-rds-enhanced-monitoring-policy"
  description = "Policy for RDS enhanced monitoring"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/rds/instance/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_attachment" {
  role       = aws_iam_role.rds_role.name
  policy_arn = aws_iam_policy.rds_enhanced_monitoring_policy.arn
}

resource "aws_iam_role" "secrets_manager_access_role" {
  name = "${var.environment}-secrets-manager-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:default:finflow-app-sa"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-secrets-manager-access-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_policy" "secrets_manager_read_policy" {
  name        = "${var.environment}-secrets-manager-read-policy"
  description = "Policy to allow reading secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_manager_prefix}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_read_attachment" {
  role       = aws_iam_role.secrets_manager_access_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

data "aws_caller_identity" "current" {}


