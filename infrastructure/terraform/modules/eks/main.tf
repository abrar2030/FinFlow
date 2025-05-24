locals {
  cluster_name = var.cluster_name
  
  # EKS cluster IAM role
  cluster_iam_role_name = "${var.cluster_name}-cluster-role"
  
  # Node groups IAM role
  node_groups_iam_role_name = "${var.cluster_name}-node-role"
  
  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Cluster     = var.cluster_name
    },
    var.tags
  )
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  count = var.create_cluster_role ? 1 : 0
  
  name = local.cluster_iam_role_name
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count = var.create_cluster_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  count = var.create_cluster_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.create_cluster_role ? aws_iam_role.cluster[0].arn : var.cluster_role_arn
  version  = var.cluster_version
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
  }
  
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
  
  tags = local.common_tags
}

# Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = local.node_groups_iam_role_name
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups
  
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids
  
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }
  
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size
  
  labels = merge(
    {
      Environment = var.environment
    },
    each.value.labels
  )
  
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
  
  tags = local.common_tags
}

# Create OIDC provider for the cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = local.common_tags
}

# Create IAM role for AWS Load Balancer Controller
resource "aws_iam_role" "lb_controller" {
  name = "${var.cluster_name}-lb-controller-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Create IAM policy for AWS Load Balancer Controller
resource "aws_iam_policy" "lb_controller" {
  name        = "${var.cluster_name}-lb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  
  policy = file("${path.module}/policies/lb-controller-policy.json")
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lb_controller" {
  policy_arn = aws_iam_policy.lb_controller.arn
  role       = aws_iam_role.lb_controller.name
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  
  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }
  
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lb_controller.arn
  }
  
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.lb_controller
  ]
}
