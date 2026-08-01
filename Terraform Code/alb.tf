// Declare Application Load Balancer named "conversion-king-alb"
resource "aws_lb" "conversion_king_alb" {
  name               = "conversion-king-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.conversion_king_public_subnet.id,
    aws_subnet.conversion_king_public_subnet_2.id
  ]

  tags = {
    Name = "conversion-king-alb"
  }
}

// Declare Target Group named "conversion-king-tg"
resource "aws_lb_target_group" "conversion_king_tg" {
  name     = "conversion-king-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.conversion_king_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "conversion-king-tg"
  }
}

// Declare ALB Listener on Port 80 forwarding to Target Group
resource "aws_lb_listener" "conversion_king_http_listener" {
  load_balancer_arn = aws_lb.conversion_king_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.conversion_king_tg.arn
  }
}