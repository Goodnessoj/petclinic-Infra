# Raw Namespace Manifests

This folder contains the raw namespace manifest used by the Kustomize overlays.

The base namespace is named `petclinic`; the dev and prod overlays rename it to
`petclinic-dev` and `petclinic-prod`.

The active application namespace is still created by the Terraform `addons`
module and can also be created by Argo CD with `CreateNamespace=true`.
