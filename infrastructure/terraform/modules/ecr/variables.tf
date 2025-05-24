variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "enable_scan_on_push" {
  description = "Whether to enable scan on push for the repositories"
  type        = bool
  default     = true
}

variable "image_retention_count" {
  description = "Number of images to keep in each repository"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
