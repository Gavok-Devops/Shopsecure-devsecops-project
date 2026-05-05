variable "project"                    { type = string }
variable "environment"                { type = string }
variable "vpc_id"                     { type = string }
variable "private_subnet_ids"         { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "db_name"                    { type = string; default = "shopsecure" }
variable "db_username"                { type = string; default = "shopsecure_admin" }
variable "instance_class"             { type = string; default = "db.m5.large" }
variable "multi_az"                   { type = bool; default = true }
variable "common_tags"                { type = map(string); default = {} }
