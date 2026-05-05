variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_admin_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the EKS API server publicly"
  default     = ["0.0.0.0/0"]  # Restrict to your office IP in production!
}
