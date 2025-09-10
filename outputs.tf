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

output "secret_manager_name" {
  value       = var.minio_secret_name
  description = "MinIO root creds are stored here in AWS Secrets Manager"
}
