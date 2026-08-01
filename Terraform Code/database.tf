//Declare ElastiCache Subnet Group using the private data subnets
resource "aws_elasticache_subnet_group" "conversion_king_elasticache_subnet_group" {
  name       = "conversion-king-elasticache-subnet-group"
  subnet_ids = [aws_subnet.conversion_king_private_data_subnet_1.id, aws_subnet.conversion_king_private_data_subnet_2.id]

  tags = {
    Name = "conversion-king-elasticache-subnet-group"
  }
}

//Declare ElastiCache Cluster named "conversion-king-redis"
resource "aws_elasticache_cluster" "conversion_king_redis" {
    cluster_id           = "conversion-king-redis"
    engine               = "redis"
    node_type            = "cache.t3.micro"
    num_cache_nodes      = 1
    parameter_group_name = "default.redis6.x"
    port                 = 6379
    subnet_group_name    = aws_elasticache_subnet_group.conversion_king_elasticache_subnet_group.name
    security_group_ids   = [aws_security_group.redis_sg.id]
    
    tags = {
        Name = "conversion-king-redis"
    }
}


// Declare RDS DB Subnet Group using Private Data Subnets
resource "aws_db_subnet_group" "conversion_king_rds_subnet_group" {
  name       = "conversion-king-rds-subnet-group"
  subnet_ids = [
    aws_subnet.conversion_king_private_data_subnet_1.id,
    aws_subnet.conversion_king_private_data_subnet_2.id
  ]

  tags = {
    Name = "conversion-king-rds-subnet-group"
  }
}

// Declare RDS Database named "conversion-king-rds"
resource "aws_db_instance" "conversion_king_rds" {
  identifier              = "conversion-king-rds"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"

  username                = "adminuser"
  password                = "AdminPass123!"
  db_subnet_group_name    = aws_db_subnet_group.conversion_king_rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = {
    Name = "conversion-king-rds"
  }
}