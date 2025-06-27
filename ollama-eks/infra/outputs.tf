output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_arn" {
  value = module.eks_cluster.cluster_arn
}
