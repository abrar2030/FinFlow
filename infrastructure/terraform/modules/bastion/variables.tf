variable "vpc_id" {
  description = "ID of the VPC where the bastion host will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the bastion host will be deployed"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for the bastion host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "allowed_cidr" {
  description = "List of CIDR blocks allowed to connect to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
