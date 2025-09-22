# outputs.tf
# Output values for the MinIO High Availability deployment
# These outputs provide important information about the deployed infrastructure
# that users need to access and manage their MinIO cluster

# ALB DNS name - the main entry point for accessing MinIO services
# This is the URL users will use to access MinIO through the load balancer
output "alb_dns_name" {
  value = aws_lb.minio_alb.dns_name
  description = "DNS name of the Application Load Balancer - main entry point for MinIO access"
}

# MinIO S3 API URL - dynamically chooses HTTP or HTTPS based on SSL configuration
# This URL can be used by S3 clients to connect to the MinIO cluster
output "minio_api_url" {
  value = var.certificate_arn != "" ? "https://${aws_lb.minio_alb.dns_name}" : "http://${aws_lb.minio_alb.dns_name}"
  description = "MinIO S3 API endpoint URL - use this for S3 client connections"
}

# MinIO Console URL - web interface for managing MinIO
# The console is accessible at /console path on the same ALB
output "minio_console_url" {
  # console is on same host; we forward /console to port 9001
  value = var.certificate_arn != "" ? "https://${aws_lb.minio_alb.dns_name}/console" : "http://${aws_lb.minio_alb.dns_name}/console"
  description = "MinIO Console web interface URL - use this to access the MinIO management interface"
}

# Bastion host public IP - for SSH access (if enabled)
# This is only useful if you have enabled the bastion host in your configuration
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
  description = "Public IP of the bastion host - use for SSH access to the VPC"
}

# MinIO node public IPs - NOTE: These will be empty after private subnet migration
# This output was useful when instances were in public subnets, but now instances
# are in private subnets and don't have public IPs for security reasons
output "minio_node_public_ips" {
  value = aws_instance.minio[*].public_ip
  description = "Public IPs of all MinIO nodes (will be empty - instances are now in private subnets)"
}

# AWS Secrets Manager secret name containing MinIO root credentials
# Users need this information to retrieve the MinIO root username and password
output "secret_manager_name" {
  value       = var.minio_secret_name
  description = "MinIO root credentials are stored here in AWS Secrets Manager - use 'aws secretsmanager get-secret-value' to retrieve"
}
