terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "auto-destroy" = "true"
      "Terraform"    = "true"
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.ai_eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.ai_eks_cluster.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.ai_eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.ai_eks_cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}
