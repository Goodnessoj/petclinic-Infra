# Look up the existing Route 53 hosted zone for the root domain
data "aws_route53_zone" "main" {
  name         = var.root_domain_name
  private_zone = false
}

# Build the full app domain name
locals {
  app_domain_name = "${var.app_subdomain}.${var.root_domain_name}"
}

# ACM Certificate for the application subdomain
resource "aws_acm_certificate" "main" {
  domain_name       = local.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "petclinic-${var.environment}-acm"
  })
}

# Route 53 DNS validation records for ACM
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

# Wait for ACM certificate validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# Note:
# The AWS Load Balancer Controller and Kubernetes Ingress are handled separately.
# After the Ingress creates the ALB, create a Route 53 A alias record for:
# petclinic.goodnessoj.site -> ALB