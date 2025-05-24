variable "vpc_id" {
  description = "ID of the VPC where the RDS instances will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the RDS instances will be deployed"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instances in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14"
}

variable "databases" {
  description = "Map of database configurations"
  type        = map(object({
    name = string
    port = number
  }))
}

variable "create_security_group" {
  description = "Whether to create a security group for RDS"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instances"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
