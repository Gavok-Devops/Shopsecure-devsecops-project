variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
