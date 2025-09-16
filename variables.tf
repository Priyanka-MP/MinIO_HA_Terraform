variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region"
}

variable "project_name" {
  type        = string
  default     = "minio-ha"
  description = "Resource name prefix"
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.0.0/20", "10.42.16.0/20", "10.42.32.0/20"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.64.0/20", "10.42.80.0/20", "10.42.96.0/20"]
}

variable "node_count" {
  type        = number
  default     = 4
  description = "MinIO nodes. Use 4, 6, or 8 for distributed erasure sets."
}

variable "instance_type" {
  type    = string
  default = "m6i.large"
}

variable "data_volume_size_gb" {
  type        = number
  default     = 500
  description = "EBS gp3 data volume size per node"
}

variable "data_volume_iops" {
  type    = number
  default = 3000
}

variable "data_volume_throughput" {
  type    = number
  default = 250
}

variable "minio_secret_name" {
  type        = string
  default     = "minio-root-credentials-new"
  description = "Secrets Manager secret name for MinIO root credentials"
}

variable "allow_ingress_cidrs_console" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Who can reach the console listener on ALB (443 or 80 if no TLS). Lock this down in prod."
}

variable "allow_ingress_cidrs_s3" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Who can reach S3 API on ALB (443 or 80 if no TLS). Prefer known CIDRs."
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN. If empty, listeners run on HTTP 80."
}

variable "enable_access_logs" {
  type        = bool
  default     = true
  description = "Enable ALB access logs to S3"
}

variable "alb_logs_bucket" {
  type        = string
  default     = ""
  description = "S3 bucket name for ALB access logs (required if enable_access_logs = true)"
}

variable "create_bastion" {
  type        = bool
  default     = false
  description = "Set true only if you really want a bastion with SSH. Otherwise, use SSM."
}
