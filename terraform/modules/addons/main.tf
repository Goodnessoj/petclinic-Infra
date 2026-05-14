locals {
  external_secrets_namespace       = "external-secrets"
  external_secrets_service_account = "external-secrets"
  load_balancer_namespace          = "kube-system"
  load_balancer_service_account    = "aws-load-balancer-controller"
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = local.external_secrets_namespace
  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
        name   = local.external_secrets_service_account
        annotations = {
          "eks.amazonaws.com/role-arn" = var.external_secrets_role_arn
        }
      }
    })
  ]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version
  namespace  = local.load_balancer_namespace

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id
      serviceAccount = {
        create = true
        name   = local.load_balancer_service_account
        annotations = {
          "eks.amazonaws.com/role-arn" = var.aws_load_balancer_controller_role_arn
        }
      }
    })
  ]
}

resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        service = {
          type = var.grafana_service_type
        }
      }
      prometheus = {
        prometheusSpec = {
          podMonitorSelectorNilUsesHelmValues     = false
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
    })
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
}

resource "kubernetes_secret_v1" "argocd_repo_credentials" {
  count = var.argocd_repo_url != "" && var.argocd_repo_token != "" ? 1 : 0

  metadata {
    name      = "petclinic-repo-credentials"
    namespace = "argocd"

    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.argocd_repo_url
    username = var.argocd_repo_username
    password = var.argocd_repo_token
  }

  depends_on = [
    helm_release.argocd
  ]
}
