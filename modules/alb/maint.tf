resource "aws_lb" "alb" {
  name               = "app-alb"
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  ip_address_type = "ipv4"
  vpc_id   = var.vpc_id
  protocol_version = "HTTP1"

  # target type IP address is the one we need
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 5
  }
}

resource "aws_lb_target_group_attachment" "targets" {
  for_each = { for idx, ip in var.target_ip_addresses : tostring(idx) => ip }

  target_group_arn  = aws_lb_target_group.tg.arn
  target_id         = each.value
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
