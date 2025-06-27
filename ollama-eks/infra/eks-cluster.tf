# Create an EKS cluster with all the necessary add-ons and node groups needed for hosting LLMs
module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  subnet_ids                               = module.vpc.private_subnets # place nodes in private subnets
  vpc_id                                   = module.vpc.vpc_id
  cluster_endpoint_public_access           = true
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  node_iam_role_name                       = "llm-cluster-node-role"

  cluster_addons = {

    vpc-cni = {}
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations = var.common_tolerations
      })
    }
  }

  eks_managed_node_groups = {
    cpu_nodes = {
      min_capacity     = var.cpu_nodes["min_capacity"]
      desired_capacity = var.cpu_nodes["desired_capacity"]
      max_capacity     = var.cpu_nodes["max_capacity"]
      instance_types   = var.cpu_nodes["instance_types"]

      node_group_name = "llm-eks-cpu-node-group"
      taints = [{
        key    = "node-type"
        value  = "cpu"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        "node-type" = "cpu"
      }
    }
  }

  depends_on = [
    module.vpc
  ]
}

# update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --alias ${var.cluster_name}"
  }

  depends_on = [module.eks_cluster]
}
