# Configurations for the required helm charts and other related
# infra for various components needed on the EKS cluster


# IAM role and service account for ALB Ingress Controller
module "aws_lb_controller_ingress_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "aws-load-balancer-controller-sa-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.ai_eks_cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "aws_lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.aws_lb_controller_ingress_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

# install ALB Ingress controller helm chart
resource "helm_release" "aws_lb_controller" {
  name         = "aws-load-balancer-controller"
  repository   = "https://aws.github.io/eks-charts"
  chart        = "aws-load-balancer-controller"
  namespace    = "kube-system"
  force_update = true

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      clusterName = var.cluster_name
      tolerations = var.common_tolerations

    })
  ]

  depends_on = [
    module.ai_eks_cluster,
    kubernetes_service_account.aws_lb_controller_sa
  ]
}

# install external-dns helm chart - for DNS management in CloudFlare
resource "helm_release" "external_dns" {
  name         = "external-dns"
  chart        = "external-dns"
  repository   = "https://charts.bitnami.com/bitnami"
  version      = "8.8.4"
  force_update = true

  values = [
    yamlencode({
      tolerations = var.common_tolerations
      provider    = "cloudflare"
      sources     = ["service", "ingress"]
      cloudflare = {
        apiToken = var.cloudflare_api_token
      }
    })
  ]

  depends_on = [
    module.ai_eks_cluster,
    helm_release.aws_lb_controller,
  ]
}
