region = "ap-south-1"

project_name           = "minio-ha"
node_count             = 4
instance_type          = "m6i.large"
data_volume_size_gb    = 500
data_volume_iops       = 3000
data_volume_throughput = 250

minio_secret_name = "minio-root-credentials-new"

# Lock these to your office/VPN in real prod
allow_ingress_cidrs_console = ["0.0.0.0/0"]
allow_ingress_cidrs_s3      = ["0.0.0.0/0"]

# Provide ACM cert ARN to enable HTTPS on ALB
certificate_arn = ""

# If you want ALB access logs
enable_access_logs = false
alb_logs_bucket    = ""
