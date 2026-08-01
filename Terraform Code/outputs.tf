// Output Application Load Balancer DNS Name
output "alb_dns_name" {
  description = "Public DNS URL of the Application Load Balancer"
  value       = aws_lb.conversion_king_alb.dns_name
}

// Output RDS Endpoint
output "rds_endpoint" {
  description = "Connection endpoint for the RDS Database"
  value       = aws_db_instance.conversion_king_rds.endpoint
}

// Output ElastiCache Redis Endpoint
output "redis_endpoint" {
  description = "Primary endpoint address for ElastiCache Redis"
  value       = aws_elasticache_cluster.conversion_king_redis.cache_nodes[0].address
}