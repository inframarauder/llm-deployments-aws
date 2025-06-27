variable "cloudflare_api_token" {
  type        = string
  description = "The CloudFlare API Key"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Version of the EKS cluster"
}

variable "node_iam_role_name" {
  type        = string
  description = "Name of the IAM role for the nodes"
}
variable "common_tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  description = "A list of tolerations to apply to all pods"
  default     = []
}

variable "cpu_nodes" {
  type = object({
    min_capacity     = optional(number, 1)
    desired_capacity = optional(number, 3)
    max_capacity     = optional(number, 10)
    instance_types   = optional(list(string), ["t3a.xlarge"])
  })
}
