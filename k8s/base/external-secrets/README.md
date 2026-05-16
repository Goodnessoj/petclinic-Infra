# External Secrets Raw Manifests

This folder is reserved for raw Kubernetes manifests related to External Secrets.

The current YAML files are empty. The active External Secrets Operator and
`ClusterSecretStore` are managed by Terraform in `terraform/modules/addons`.

Application `ExternalSecret` resources are rendered by the
`helm/petclinic-secrets` chart.
