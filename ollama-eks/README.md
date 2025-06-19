# ollama-eks
A complete Kubernetes platform on Amazon EKS to run various LLMs via Ollama.

Steps to run - 
1. Create a `infra/terraform.tfvars` file with the required values (refer `infra/variables.tf`)
2. `cd infra && terraform apply -auto-approve`
3. `kubectl apply k8s-config/`

Cleanup - 
1. Delete all k8s resources - `kubectl delelte <resource>`
2. `cd infra && terraform destroy -auto-approve`