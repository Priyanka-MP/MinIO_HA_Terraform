output "alb_dns_name" {
  value = aws_lb.minio_alb.dns_name
}

output "minio_api_url" {
  value = var.certificate_arn != "" ? "https://${aws_lb.minio_alb.dns_name}" : "http://${aws_lb.minio_alb.dns_name}"
}

output "minio_console_url" {
  # console is on same host; we forward /console to port 9001
  value = var.certificate_arn != "" ? "https://${aws_lb.minio_alb.dns_name}/console" : "http://${aws_lb.minio_alb.dns_name}/console"
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "minio_node_public_ips" {
  value = aws_instance.minio[*].public_ip
  description = "Public IPs of all MinIO nodes"
}

output "secret_manager_name" {
  value       = var.minio_secret_name
  description = "MinIO root creds are stored here in AWS Secrets Manager"
}
