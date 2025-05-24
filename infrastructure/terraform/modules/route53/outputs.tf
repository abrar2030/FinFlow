output "zone_id" {
  description = "The ID of the hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "The name servers of the hosted zone"
  value       = data.aws_route53_zone.main.name_servers
}

output "record_names" {
  description = "The names of the created DNS records"
  value       = { for k, v in aws_route53_record.main : k => v.name }
}

output "record_fqdns" {
  description = "The FQDNs of the created DNS records"
  value       = { for k, v in aws_route53_record.main : k => v.fqdn }
}
