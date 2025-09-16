# ALB SG allows inbound from world (you will likely restrict this)
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.certificate_arn != "" ? toset(["443"]) : toset(["80"])
    content {
      from_port   = tonumber(ingress.value)
      to_port     = tonumber(ingress.value)
      protocol    = "tcp"
      cidr_blocks = concat(var.allow_ingress_cidrs_s3, var.allow_ingress_cidrs_console)
      description = "ALB listener"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# Node SG allows only from ALB on 9000 (API) and 9001 (console)
resource "aws_security_group" "node_sg" {
  name   = "${var.project_name}-node-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description     = "S3 API"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Console"
    from_port       = 9001
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # cluster traffic between nodes (erasure/distribution)
  ingress {
    description = "Inter-node"
    from_port   = 9000
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  # allow SSM/CloudWatch agents outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-node-sg" }
}
