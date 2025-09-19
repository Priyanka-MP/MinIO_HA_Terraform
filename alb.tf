resource "aws_lb" "minio_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.alb_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.alb_logs_bucket
      enabled = true
      prefix  = "${var.project_name}/alb"
    }
  }

  tags = { Name = "${var.project_name}-alb" }
}

# TG for MinIO S3 API (9000)
resource "aws_lb_target_group" "tg_api" {
  name        = "${var.project_name}-tg-api"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/minio/health/ready"
    matcher             = "200-399"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = { Name = "${var.project_name}-tg-api" }
}

# TG for Console (9001)
resource "aws_lb_target_group" "tg_console" {
  name        = "${var.project_name}-tg-console"
  port        = 9001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  # console doesn't expose its own health path; check API health instead
  health_check {
    path                = "/minio/health/ready"
    port                = 9000
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = { Name = "${var.project_name}-tg-console" }
}

# Register instances later (after instances created) in instances.tf

# Listeners
resource "aws_lb_listener" "http" {
  count             = var.certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.minio_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_api.arn
  }
}

# Optional HTTPS (host/path routing)
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.minio_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_api.arn
  }
}

# On 443, send /console to console TG
resource "aws_lb_listener_rule" "https_console" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_console.arn
  }

  condition {
    path_pattern {
      values = ["/console*", "/login*"]
    }
  }
}

# On 80, route /console as well (if no TLS)
resource "aws_lb_listener_rule" "http_console" {
  count        = var.certificate_arn == "" ? 1 : 0
  listener_arn = aws_lb_listener.http[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_console.arn
  }

  condition {
    path_pattern {
      values = ["/console*", "/login*"]
    }
  }
}
