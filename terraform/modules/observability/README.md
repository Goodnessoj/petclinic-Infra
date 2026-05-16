# Observability Module

This module creates AWS-side observability resources.

## Resources

- CloudWatch log group for the EKS cluster.
- CloudWatch log group for each Petclinic service.
- CloudWatch dashboard named `PetClinic-<environment>`.

## Services Covered

- `config-server`
- `discovery-server`
- `api-gateway`
- `customers-service`
- `visits-service`
- `vets-service`
- `genai-service`
- `admin-server`

## Inputs

| Variable | Description |
| --- | --- |
| `project_name` | Project identifier used for naming. |
| `environment` | Environment name. |
| `aws_region` | Region used in CloudWatch dashboard widgets. |
| `enable_container_insights` | Reserved input for container insights integration. |
| `log_retention_days` | Intended default retention period. Current log groups use 30 days. |
| `tags` | Tags applied to resources where supported. |

## Outputs

- `log_retention_days`
- `log_group_names`
- `cluster_log_group_name`

## Relationship To Kubernetes Monitoring

This module is separate from the Kubernetes monitoring stack. The
`terraform/modules/addons` module installs kube-prometheus-stack, Grafana, Loki,
and Kubernetes dashboard resources.
