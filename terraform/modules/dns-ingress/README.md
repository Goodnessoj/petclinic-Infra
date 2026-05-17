# DNS Ingress Module

This module prepares DNS and TLS resources for ALB-backed application and
platform ingress.

## Resources

- Looks up an existing public Route 53 hosted zone.
- Creates an ACM certificate for the application hostname.
- Adds subject alternative names for additional hostnames such as Argo CD,
  Grafana, Prometheus, and any public service dashboards.
- Creates Route 53 DNS validation records.
- Waits for ACM certificate validation.

## Hostname Model

The main app hostname is:

```text
<app_subdomain>.<root_domain_name>
```

Additional hostnames are created from:

```text
<additional_subdomain>.<root_domain_name>
```

The dev root passes Argo CD, Grafana, Prometheus, `eureka`, and `discovery` as
additional names. The prod root passes Argo CD, Grafana, and Prometheus.

## Inputs

Important active inputs:

- `environment`
- `root_domain_name`
- `app_subdomain`
- `additional_subdomains`
- `aws_region`
- `tags`

The module also accepts EKS and load balancer related inputs
(`cluster_name`, `cluster_endpoint`, `cluster_ca_certificate`,
`lb_controller_service_account`) for compatibility with earlier designs, but the
current resources do not create Kubernetes ingress objects here.

## Outputs

- `route53_zone_id`
- `root_domain_name`
- `app_domain_name`
- `additional_domain_names`
- `acm_certificate_arn`
- `acm_certificate_validation_id`
- `hosted_zone_name_servers`

## Relationship To Add-Ons

This module creates the certificate. The `addons` module uses the certificate
ARN to expose Argo CD, Grafana, and Prometheus through ALB ingresses. The
service Helm chart can expose application services through ALB ingresses when
ingress values are enabled.
