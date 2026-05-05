variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for EKS"
  default     = "1.31"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS node groups"
}

variable "cluster_admin_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the EKS public API endpoint"
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
