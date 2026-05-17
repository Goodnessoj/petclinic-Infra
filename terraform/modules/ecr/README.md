# ECR Module

This module creates container repositories for the Petclinic services.

## Repositories

The module creates one repository for each service:

- `config-server`
- `discovery-server`
- `api-gateway`
- `customers-service`
- `vets-service`
- `visits-service`
- `admin-server`
- `genai-service`

Repository names are built as:

```text
<repository_prefix>-<service-name>
```

For the dev defaults, that produces names such as
`petclinic-dev-api-gateway`.

## Behavior

- Image tags are mutable.
- Scan on push is enabled.
- AES256 encryption is enabled.
- A lifecycle policy keeps the last 10 images.
- `force_delete = true` allows Terraform destroy to delete repositories that
  still contain images.

## Inputs

| Variable | Description |
| --- | --- |
| `environment` | Environment tag value. |
| `repository_prefix` | Plain prefix without a trailing hyphen. |
| `tags` | Extra tags applied to repositories. |

## Outputs

- `repository_urls`: map of service name to full ECR repository URL.
- `repository_names`: list of created repository names.
- `registry_url`: registry hostname without a repository name.

## Safety Notes

Use caution before destroying environments that use this module. Because
`force_delete = true`, repository deletion also deletes contained images.
