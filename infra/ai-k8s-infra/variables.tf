variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "ai-infra-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "ai-infra-eks-cluster"
}

variable "eks_cluster_version" {
  type        = string
  description = "Version of the EKS cluster"
  default     = "1.33"
}

variable "cpu_nodes" {
  type = object({
    min_capacity     = number
    desired_capacity = number
    max_capacity     = number
    instance_types   = list(string)
    node_group_name  = string
  })

  description = "The configuration of the CPU nodes"
  default = {
    min_capacity     = 1
    desired_capacity = 3
    max_capacity     = 10
    instance_types   = ["t3a.xlarge", "t3a.2xlarge"]
    node_group_name  = "ai-cpu-nodes"
  }
}

variable "gpu_nodes" {
  type = object({
    min_capacity     = number
    desired_capacity = number
    max_capacity     = number
    instance_types   = list(string)
    node_group_name  = string
  })

  description = "The configuration of the GPU nodes"
  default = {
    min_capacity     = 0
    desired_capacity = 0 # not creating gpu instances for now
    max_capacity     = 4 # cuz the mofos at AWS wont increase my quotas!
    instance_types   = ["g4dn.xlarge"]
    node_group_name  = "ai-gpu-nodes"
  }
}
