resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "cloudtrail-logs-${var.environment}"
  retention_in_days = 365 # Retain logs for 1 year

  tags = merge(
    {
      Name        = "cloudtrail-logs-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudtrail" "finflow_trail" {
  name                          = "finflow-cloudtrail-${var.environment}"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail/"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = var.cloudwatch_logs_role_arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail_log_group.arn

  tags = merge(
    {
      Name        = "finflow-cloudtrail-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.s3_bucket_name

  tags = merge(
    {
      Name        = "${var.s3_bucket_name}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/cloudtrail/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "${var.environment}-cloudtrail-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-cloudtrail-cloudwatch-logs-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "${var.environment}-cloudtrail-cloudwatch-logs-policy"
  role = aws_iam_role.cloudwatch_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}


