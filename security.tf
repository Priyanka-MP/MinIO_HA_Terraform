# security.tf
# Security groups configuration for MinIO High Availability deployment
# This file defines the network access rules for all components in the architecture
# Security groups act as virtual firewalls controlling traffic between resources

# Bastion host security group - allows SSH access for administrative purposes
# WARNING: This allows SSH from anywhere (0.0.0.0/0) - restrict in production!
resource "aws_security_group" "bastion_sg" {
  name   = "${var.project_name}-bastion-sg"
  vpc_id = aws_vpc.this.id

  # Inbound rule for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # WARNING: Restrict this in production!
    description = "SSH access to bastion host"
  }

  # Outbound rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-bastion-sg" }
}

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

  # Allow inbound from ALB on ephemeral ports (for health checks)
  ingress {
    description     = "ALB health checks"
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  tags = { Name = "${var.project_name}-node-sg" }
}
