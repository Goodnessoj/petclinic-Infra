# ArgoCD GitOps

This folder installs ArgoCD and registers one ArgoCD Application per Petclinic service.

Runtime prerequisites still need to exist before the services become healthy:

- `mysql-secret` in the target namespace, normally created by External Secrets.
- `openai-secret` in the target namespace for `genai-service`. This secret is not committed to Git.

For this EKS cluster, ArgoCD is installed by the Terraform addons module with the `argo-cd` Helm chart. Re-apply Terraform when you need to install or upgrade ArgoCD itself.

The `install/` folder vendors the upstream install manifest as a fallback bootstrap option for a cluster that is not already Helm-managing ArgoCD. Do not apply that layer over the Terraform-managed `argocd` Helm release.

Fallback bootstrap for a fresh, non-Helm-managed cluster:

```bash
kubectl apply --server-side --force-conflicts -k k8s/argocd/install
```

Apply only the dev GitOps layer to this dev cluster:

```bash
kubectl apply -f k8s/argocd/applications/project.yaml
kubectl apply -k k8s/argocd/applications/dev
```

Dev applications sync automatically with prune and self-heal enabled. Prod applications are manual sync, with prune available during manual sync.

The Helm value files are intentionally ordered as environment first, service second:

```yaml
valueFiles:
  - ../../helm-values/dev.yaml
  - ../../helm-values/customers-service.yaml
```

ArgoCD and Helm merge later files last, and this repo stores the service image repository and tag in the per-service values files.

Open the ArgoCD UI through DNS after the Terraform addons layer applies:

```text
https://argocd.phoniex.site
```

The local fallback is:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Then browse to `https://localhost:8080`.

Get the initial admin password with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
