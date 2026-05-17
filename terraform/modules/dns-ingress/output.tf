output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "root_domain_name" {
  description = "Root domain name"
  value       = var.root_domain_name
}

output "app_domain_name" {
  description = "Full application domain name"
  value       = local.app_domain_name
}

output "additional_domain_names" {
  description = "Additional hostnames covered by the ACM certificate."
  value       = local.additional_domain_names
}

output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "acm_certificate_validation_id" {
  description = "ACM certificate validation ID"
  value       = aws_acm_certificate_validation.main.id
}

output "hosted_zone_name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = data.aws_route53_zone.main.name_servers
}
