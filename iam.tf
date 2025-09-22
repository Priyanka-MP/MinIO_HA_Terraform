# iam.tf
# IAM roles and policies for MinIO High Availability deployment
# This file configures the necessary permissions for MinIO instances to:
# - Access AWS Secrets Manager for root credentials
# - Use AWS Systems Manager (SSM) for remote management
# - Generate and store MinIO root credentials securely

# IAM Role for EC2 nodes to use SSM and read from Secrets Manager
# This role is attached to all MinIO instances and provides necessary permissions
resource "aws_iam_role" "minio_node_role" {
  name               = "${var.project_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  description        = "IAM role for MinIO nodes with SSM and Secrets Manager access"
}

# Trust policy: allow EC2 service to assume role
# This policy document defines which AWS services can assume this role
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # Only EC2 instances can assume this role
    }
  }
}

# Attach AmazonSSMManagedInstanceCore for SSM Session Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.minio_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow EC2 to read the specific MinIO secret
data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid = "SecretsRead"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.minio_root.arn]
  }
}

resource "aws_iam_policy" "minio_secret_read" {
  name   = "${var.project_name}-secrets-read"
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_role_policy_attachment" "secret_read_attach" {
  role       = aws_iam_role.minio_node_role.name
  policy_arn = aws_iam_policy.minio_secret_read.arn
}

# Instance Profile so EC2 can assume the role
resource "aws_iam_instance_profile" "minio_node_profile" {
  name = "${var.project_name}-node-profile"
  role = aws_iam_role.minio_node_role.name
}

# --------------------------
# Root credentials in Secrets Manager
# --------------------------

# Randomly generate root user (letters/numbers only)
resource "random_password" "minio_root_user" {
  length  = 12
  special = false
}

# Randomly generate root password (letters + numbers + symbols)
resource "random_password" "minio_root_password" {
  length      = 16
  special     = true
  min_special = 2
}

# Secret container
resource "aws_secretsmanager_secret" "minio_root" {
  name = var.minio_secret_name
  tags = { Name = "${var.project_name}-minio-root" }
}

# Secret version with JSON creds
resource "aws_secretsmanager_secret_version" "minio_root_value" {
  secret_id = aws_secretsmanager_secret.minio_root.id
  secret_string = jsonencode({
    access_key = random_password.minio_root_user.result
    secret_key = random_password.minio_root_password.result
  })
}
