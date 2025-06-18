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
    gpu_nodes = {
      min_capacity     = var.gpu_nodes["min_capacity"]
      desired_capacity = var.gpu_nodes["desired_capacity"]
      max_capacity     = var.gpu_nodes["max_capacity"]
      instance_types   = var.gpu_nodes["instance_types"]
      node_group_name  = var.gpu_nodes["node_group_name"]

      taints = [{
        key    = "node-type"
        value  = "gpu"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        "node-type" = "gpu"
      }
    }
  }
}

# update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.eks_cluster_name} --alias ${var.eks_cluster_name}"
  }

  depends_on = [module.ai_eks_cluster]
}
