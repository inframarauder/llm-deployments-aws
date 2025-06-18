terraform {
  backend "s3" {
    bucket       = "inframarauder-tf-state"
    key          = "ai-k8s-infra/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
