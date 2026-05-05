output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "ecr_registry_id"  { value = module.ecr.registry_id }
output "db_endpoint"      { value = module.rds.db_endpoint }
output "redis_endpoint"   { value = module.elasticache.redis_endpoint }
output "vpc_id"           { value = module.vpc.vpc_id }
