# variables.tf
# Input variables for the MinIO High Availability deployment
# These variables control the configuration of the entire infrastructure

# AWS region where resources will be deployed
# Default is ap-south-1 (Mumbai), but can be changed to any AWS region
variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region where all resources will be deployed"
}

# Project name prefix used for all resource names
# This helps with resource identification and organization
variable "project_name" {
  type        = string
  default     = "minio-ha"
  description = "Resource name prefix for all AWS resources (VPC, subnets, security groups, etc.)"
}

# VPC CIDR block - defines the IP range for the entire VPC
# 10.42.0.0/16 provides 65,536 IP addresses
variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
  description = "CIDR block for the VPC - defines the IP address range for the entire network"
}

# Public subnet CIDR blocks - where ALB and NAT gateways will be deployed
# Each /20 subnet provides 4,096 IP addresses
# Three subnets for high availability across availability zones
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.0.0/20", "10.42.16.0/20", "10.42.32.0/20"]
  description = "CIDR blocks for public subnets - ALB and NAT gateways will be deployed here"
}

# Private subnet CIDR blocks - where MinIO instances will be deployed
# Each /20 subnet provides 4,096 IP addresses
# Three subnets for high availability across availability zones
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.64.0/20", "10.42.80.0/20", "10.42.96.0/20"]
  description = "CIDR blocks for private subnets - MinIO instances will be deployed here"
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
