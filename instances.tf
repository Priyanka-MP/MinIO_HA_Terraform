# Latest Amazon Linux 2023 (or switch to Ubuntu if you prefer) 
data "aws_ami" "al2023" {
  owners      = ["137112412989"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

locals {
  # spread nodes across private subnets
  selected_private_subnets = [for s in aws_subnet.private : s.id]
}

resource "aws_instance" "minio" {
  count                       = var.node_count
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = "minio-key-new"
  subnet_id                   = element(values(aws_subnet.public).*.id, count.index % length(aws_subnet.public))
  associate_public_ip_address = true
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
    SECRET_NAME  = var.minio_secret_name
    PEER_ARGS    = join(" ", [for ip in local.expected_ips : "http://${ip}:9000"])
    DATA_DEVICE  = "/dev/nvme1n1"  # AL2023 maps EBS to nvme
    DATA_MOUNT   = "/mnt/minio"
    CONSOLE_PORT = 9001
    API_PORT     = 9000
  })


  tags = {
    Name = "${var.project_name}-node-${count.index + 1}"
    Role = "minio"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = "minio-key-new"
  subnet_id                   = element(values(aws_subnet.public).*.id, 0)
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.minio_node_profile.name

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
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
