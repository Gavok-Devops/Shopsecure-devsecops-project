variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "cluster_admin_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the EKS public API endpoint. Restrict to your IP in production."
  default     = ["0.0.0.0/0"]
}
