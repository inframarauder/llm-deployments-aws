# Create an EKS cluster 
module "ai_eks_cluster" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                             = var.eks_cluster_name
  cluster_version                          = var.eks_cluster_version
  subnet_ids                               = module.ai_vpc.private_subnets # place nodes in private subnets
  vpc_id                                   = module.ai_vpc.vpc_id
  cluster_endpoint_public_access           = true
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  node_iam_role_name                       = "eks-ai-node-role"

  cluster_addons = {

    vpc-cni = {}
    coredns = {
      addon_versions              = "v1.12.1-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations = [{
          key      = "node-type"
          operator = "Equal"
          value    = "cpu"
          effect   = "NoSchedule"
        }]
      })
    }
  }

  eks_managed_node_groups = {
    cpu_nodes = {
      min_capacity     = var.cpu_nodes["min_capacity"]
      desired_capacity = var.cpu_nodes["desired_capacity"]
      max_capacity     = var.cpu_nodes["max_capacity"]
      instance_types   = var.cpu_nodes["instance_types"]
      node_group_name  = var.cpu_nodes["node_group_name"]

      taints = [{
        key    = "node-type"
        value  = "cpu"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        "node-type" = "cpu"
      }
    }

    # lets not burn our pockets at the moment ;__;
    # gpu_nodes = {
    #   min_capacity     = var.gpu_nodes["min_capacity"]
    #   desired_capacity = var.gpu_nodes["desired_capacity"]
    #   max_capacity     = var.gpu_nodes["max_capacity"]
    #   instance_types   = var.gpu_nodes["instance_types"]
    #   node_group_name  = var.gpu_nodes["node_group_name"]

    #   taints = [{
    #     key    = "node-type"
    #     value  = "gpu"
    #     effect = "NO_SCHEDULE"
    #   }]

    #   tags = {
    #     "node-type" = "gpu"
    #   }
    # }
  }
}

# update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.eks_cluster_name} --alias ${var.eks_cluster_name}"
  }

  depends_on = [module.ai_eks_cluster]
}

# setup AWS Load Balancer Controller via helm chart
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

resource "helm_release" "aws_lb_controller" {
  name         = "aws-load-balancer-controller"
  repository   = "https://aws.github.io/eks-charts"
  chart        = "aws-load-balancer-controller"
  namespace    = "kube-system"
  force_update = true
  replace      = true

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      clusterName = var.eks_cluster_name
      tolerations = [
        {
          key      = "node-type"
          operator = "Equal"
          value    = "cpu"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [
    module.ai_eks_cluster,
    kubernetes_service_account.aws_lb_controller_sa
  ]
}



# setup external dns via helm chart
resource "helm_release" "external_dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "1.16.1"

  values = [
    yamlencode({
      tolerations = [
        {
          key      = "node-type"
          operator = "Equal"
          value    = "cpu"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [module.ai_eks_cluster, helm_release.aws_lb_controller]
}
