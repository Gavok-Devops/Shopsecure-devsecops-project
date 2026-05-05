variable "project"             { type = string }
variable "environment"         { type = string }
variable "kubernetes_version"  { type = string; default = "1.31" }
variable "vpc_id"              { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "cluster_admin_cidrs" { type = list(string); default = ["0.0.0.0/0"] }
variable "common_tags"         { type = map(string); default = {} }
