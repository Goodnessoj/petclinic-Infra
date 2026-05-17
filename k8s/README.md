# Kubernetes Manifests

This folder contains Kubernetes and Argo CD manifests for the Petclinic
platform.

## Structure

| Path | Purpose |
| --- | --- |
| [`argocd`](argocd/README.md) | Active GitOps configuration for Argo CD installation fallback and service Applications. |
| [`base`](base/README.md) | Raw Kubernetes reference manifests for the eight services and shared secrets. |
| [`overlays`](overlays/README.md) | Dev and prod Kustomize overlays for the raw manifests. |

## Active Deployment Path

The active application path is:

```text
k8s/argocd/applications -> helm/petclinic-service -> helm-values
```

Terraform installs Argo CD through the `addons` module. Argo CD then renders the
service Helm chart once per service using the environment and service values
files.

## Raw Manifest Reference

Before the deployment moved to Helm, the service shape was captured as raw
Kubernetes manifests:

```text
k8s/base -> k8s/overlays/dev
k8s/base -> k8s/overlays/prod
```

Render them for review with:

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/prod
```

Do not apply the raw overlays to the same namespaces while Argo CD is managing
the Helm releases.

## Manual Dev Apply

After Terraform creates the cluster and Argo CD is running:

```bash
kubectl apply -f k8s/argocd/applications/project.yaml
kubectl apply -k k8s/argocd/applications/dev
```

Check status:

```bash
kubectl get applications -n argocd -o wide
kubectl get pods -n petclinic-dev
```

## Runtime Prerequisites

Before application pods become healthy, these platform pieces must exist:

- External Secrets Operator CRDs.
- `ClusterSecretStore` named `aws-secrets-manager`.
- Kubernetes `mysql-secret` in the application namespace.
- Kubernetes `openai-secret` in the application namespace for `genai-service`.
- AWS Load Balancer Controller when ingress is enabled.
- kube-prometheus-stack when PodMonitors are enabled.
