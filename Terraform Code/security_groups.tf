//Declare Security Group named "alb-sg"
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Handles public web traffic ingress."
  vpc_id      = aws_vpc.conversion_king_vpc.id

  # HTTP (Port 80) from 0.0.0.0/0
    ingress {
        description = "HTTP from 0.0.0.0/0"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # HTTP (Port 80) to 0.0.0.0/0
    egress {
        description = "HTTP to 0.0.0.0/0"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


//Declare Security Group named "app-ec2-sg"
resource "aws_security_group" "app_ec2_sg" {
  name        = "app-ec2-sg"
  description = "Restricts app access strictly to ALB requests; allows NAT egress."
  vpc_id      = aws_vpc.conversion_king_vpc.id

    # HTTP (Port 80) from ALB Security Group
    ingress {
        description = "HTTP from ALB Security Group"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    # All traffic (All Ports) to 0.0.0.0/0
    egress {
        description = "All traffic to 0.0.0.0/0"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


//Declare Security Group named "redis-sg"
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Protects ElastiCache cluster from external access."
  vpc_id      = aws_vpc.conversion_king_vpc.id

    # Custom TCP (Port 6379) from app-ec2-sg
    ingress {
        description = "Custom TCP from app-ec2-sg"
        from_port   = 6379
        to_port     = 6379
        protocol    = "tcp"
        security_groups = [aws_security_group.app_ec2_sg.id]
    }

    # All traffic (All Ports) Default
    egress {
        description = "All traffic to to Default"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


//Declare Security Group named "rds-sg"
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Protects RDS Database from non-application queries."
  vpc_id      = aws_vpc.conversion_king_vpc.id

    # MySQL/Aurora (Port 3306) from app-ec2-sg
    ingress {
        description = "MySQL/Aurora from app-ec2-sg"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.app_ec2_sg.id]
    }

    # All traffic (All Ports) Default
    egress {
        description = "All traffic to Default"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}