variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}


