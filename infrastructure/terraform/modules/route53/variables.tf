variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "record_sets" {
  description = "Map of DNS record configurations"
  type        = map(object({
    name  = string
    type  = string
    ttl   = optional(number)
    records = optional(list(string))
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
