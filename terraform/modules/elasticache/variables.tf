variable "project"                    { type = string }
variable "environment"                { type = string }
variable "vpc_id"                     { type = string }
variable "private_subnet_ids"         { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "node_type"                  { type = string; default = "cache.m5.large" }
variable "common_tags"                { type = map(string); default = {} }
