resource "aws_instance" "test_ssh" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = "minio-key-new-download"
  subnet_id                   = element(values(aws_subnet.public).*.id, 0)
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "test-ssh-instance"
  }
}

output "test_instance_public_ip" {
  value = aws_instance.test_ssh.public_ip
}
