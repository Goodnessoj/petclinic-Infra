locals {
  external_secrets_namespace       = "external-secrets"
  external_secrets_service_account = "external-secrets"
  application_namespace            = "petclinic-dev"
  load_balancer_namespace          = "kube-system"
  load_balancer_service_account    = "aws-load-balancer-controller"

  platform_ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/listen-ports"       = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
    "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
    "alb.ingress.kubernetes.io/certificate-arn"    = var.platform_certificate_arn
    "alb.ingress.kubernetes.io/group.name"         = var.platform_alb_group_name
    "alb.ingress.kubernetes.io/load-balancer-name" = var.platform_alb_name
  }
}

data "aws_route53_zone" "platform" {
  count = var.enable_platform_ingress ? 1 : 0

  name         = var.root_domain_name
  private_zone = false
}

resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = local.application_namespace

    labels = {
      "app.kubernetes.io/name"    = "petclinic"
      "app.kubernetes.io/part-of" = "petclinic"
      "petclinic.io/environment"  = "dev"
    }
  }
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

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"

    metadata = {
      name = "aws-secrets-manager"
    }

    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = local.external_secrets_service_account
                namespace = local.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.external_secrets
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

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      redis = {
        serviceAccount = {
          name = "argocd-redis"
        }
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "argocd" {
  count = var.enable_platform_ingress ? 1 : 0

  metadata {
    name      = "argocd"
    namespace = "argocd"

    labels = {
      "app.kubernetes.io/name"    = "argocd"
      "app.kubernetes.io/part-of" = "petclinic-platform"
    }

    annotations = local.platform_ingress_annotations
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.argocd_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "argocd-server"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true

  depends_on = [
    helm_release.argocd,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "aws_route53_record" "argocd" {
  count = var.enable_platform_ingress ? 1 : 0

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.platform[0].zone_id
  name            = var.argocd_hostname
  type            = "CNAME"
  ttl             = 60
  records         = [kubernetes_ingress_v1.argocd[0].status[0].load_balancer[0].ingress[0].hostname]
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
