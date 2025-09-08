# Latest Amazon Linux 2023 (or switch to Ubuntu if you prefer)
data "aws_ami" "al2023" {
  owners      = ["137112412989"]
  most_recent = true
  filter { name = "name"; values = ["al2023-ami-*-kernel-6.1-x86_64"] }
}

locals {
  # spread nodes across private subnets
  selected_private_subnets = [for s in aws_subnet.private : s.id]
}

resource "aws_instance" "minio" {
  count                       = var.node_count
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = element(local.selected_private_subnets, count.index % length(local.selected_private_subnets))
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.node_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.minio_node_profile.name

  # Root + one data volume (xvdb)
  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp3"
    volume_size           = var.data_volume_size_gb
    iops                  = var.data_volume_iops
    throughput            = var.data_volume_throughput
    delete_on_termination = false
  }

  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    secret_name    = var.minio_secret_name
    peers          = join(" ", aws_instance.minio.*.private_ip)
    data_device    = "/dev/xvdb"
    data_mount     = "/mnt/minio"
    console_port   = 9001
    api_port       = 9000
  })

  tags = {
    Name = "${var.project_name}-node-${count.index + 1}"
    Role = "minio"
  }
}

# Register instances to ALB target groups
resource "aws_lb_target_group_attachment" "api_attach" {
  for_each         = { for i, inst in aws_instance.minio : i => inst }
  target_group_arn = aws_lb_target_group.tg_api.arn
  target_id        = each.value.id
  port             = 9000
}

resource "aws_lb_target_group_attachment" "console_attach" {
  for_each         = { for i, inst in aws_instance.minio : i => inst }
  target_group_arn = aws_lb_target_group.tg_console.arn
  target_id        = each.value.id
  port             = 9001
}
