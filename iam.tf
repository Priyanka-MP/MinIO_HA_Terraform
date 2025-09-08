# Let instances use SSM and read Secrets Manager secret
resource "aws_iam_role" "minio_node_role" {
  name               = "${var.project_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.minio_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

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

resource "aws_iam_instance_profile" "minio_node_profile" {
  name = "${var.project_name}-node-profile"
  role = aws_iam_role.minio_node_role.name
}

# Root credentials in Secrets Manager
resource "random_password" "minio_root_password" {
  length           = 24
  special          = true
  override_characters = "!@#$%^&*()-_=+[]{}<>?"
}

resource "random_password" "minio_root_user" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "minio_root" {
  name = var.minio_secret_name
  tags = { Name = "${var.project_name}-minio-root" }
}

resource "aws_secretsmanager_secret_version" "minio_root_value" {
  secret_id     = aws_secretsmanager_secret.minio_root.id
  secret_string = jsonencode({
    access_key = random_password.minio_root_user.result
    secret_key = random_password.minio_root_password.result
  })
}
