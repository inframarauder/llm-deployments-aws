output "vpc_id" {
  value = module.ai_vpc.vpc_id
}

output "eks_cluster_arn" {
  value = module.ai_eks_cluster.cluster_arn
}
