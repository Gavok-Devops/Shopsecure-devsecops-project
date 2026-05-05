variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to connect to RDS"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "shopsecure"
}

variable "db_username" {
  type        = string
  description = "Master database username"
  default     = "shopsecure_admin"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.m5.large"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ for high availability"
  default     = true
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy. Set true for teardown, false for production."
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on RDS. Set false before destroying."
  default     = false
}
