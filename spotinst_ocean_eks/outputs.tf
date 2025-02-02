output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

output "kubeconfig_filename" {
  description = "The filename of the generated kubectl config."
  value       = module.eks.kubeconfig_filename
}

output "config_map_aws_auth" {
  description = ""
  value       = module.eks.config_map_aws_auth
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "worker_iam_role_arn" {
  description = "Worker IAM Role"
  value       = module.eks.worker_iam_role_arn
}

output "controller_id" {
  description = "controller_id of controlling node"
  value       = var.controller_id
}

output "cluster_id" {
  description = "cluster_id"
  value       = module.eks.cluster_id
}

