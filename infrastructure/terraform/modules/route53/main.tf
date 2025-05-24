locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Get the hosted zone for the domain
data "aws_route53_zone" "main" {
  name = var.domain_name
  private_zone = false
}

# Create record sets
resource "aws_route53_record" "main" {
  for_each = var.record_sets
  
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name != "" ? "${each.value.name}.${var.domain_name}" : var.domain_name
  type    = each.value.type
  
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
  
  ttl     = each.value.alias == null ? (each.value.ttl != null ? each.value.ttl : 300) : null
  records = each.value.alias == null ? each.value.records : null
}
