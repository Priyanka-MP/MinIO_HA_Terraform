# MinIO High Availability Deployment on AWS

This Terraform configuration deploys a highly available MinIO object storage cluster on AWS with enterprise-grade security and networking architecture.

## 🏗️ Architecture Overview

### Network Architecture
- **VPC**: Custom VPC with public and private subnets across multiple availability zones
- **Public Subnets**: Host Application Load Balancer (ALB) and NAT Gateways
- **Private Subnets**: Host MinIO server instances (secure, no direct internet access)
- **NAT Gateways**: Enable outbound internet access for private instances
- **Security Groups**: Restrictive firewall rules following principle of least privilege

### Application Architecture
- **Load Balancer**: Application Load Balancer distributes traffic to MinIO instances
- **MinIO Cluster**: Distributed MinIO servers in private subnets for high availability
- **Health Checks**: Automated health monitoring and failover
- **SSL/TLS**: Optional HTTPS support with ACM certificates

### Security Architecture
- **Private Networking**: MinIO instances in private subnets, not directly accessible from internet
- **IAM Roles**: Secure credential management using AWS IAM roles and instance profiles
- **Secrets Manager**: MinIO root credentials stored securely in AWS Secrets Manager
- **Security Groups**: Network-level access control with specific port restrictions

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- AWS account with sufficient quotas for EC2, EBS, and VPC resources

## 🚀 Quick Start

1. **Clone and navigate to the repository**
   ```bash
   git clone <repository-url>
   cd minio-ha-terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and customize variables** (optional)
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired configuration
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## ⚙️ Configuration

### Required Variables
- `region`: AWS region (default: ap-south-1)
- `project_name`: Resource name prefix (default: minio-ha)

### Optional Variables
- `node_count`: Number of MinIO nodes (default: 4, use 4, 6, or 8 for erasure sets)
- `instance_type`: EC2 instance type (default: m6i.large)
- `data_volume_size_gb`: EBS volume size per node (default: 500GB)
- `certificate_arn`: ACM certificate ARN for HTTPS (optional)
- `allow_ingress_cidrs_s3`: CIDR blocks allowed to access S3 API
- `allow_ingress_cidrs_console`: CIDR blocks allowed to access MinIO Console

## 🔐 Security Features

### Network Security
- MinIO instances deployed in private subnets
- No direct public IP addresses on MinIO instances
- Security groups restrict traffic to specific ports and sources
- Network ACLs provide additional layer of protection

### Access Control
- IAM roles for secure credential management
- Secrets Manager for storing MinIO root credentials
- SSM access for remote instance management without SSH

### Encryption
- Data at rest: MinIO handles encryption internally
- Data in transit: HTTPS support via ALB
- EBS volumes encrypted by default

## 🌐 Access Information

After deployment, Terraform outputs will provide:

- **ALB DNS Name**: Main entry point for MinIO services
- **MinIO API URL**: S3-compatible API endpoint
- **MinIO Console URL**: Web management interface
- **Secrets Manager Name**: Location of root credentials

### Retrieving Root Credentials
```bash
aws secretsmanager get-secret-value \
  --secret-id minio-root-credentials-new \
  --query SecretString \
  --output text | jq -r '.'
```

## 🔧 Management

### Scaling
- Increase `node_count` variable (must be 4, 6, or 8 for erasure coding)
- Run `terraform apply` to scale the cluster

### Updates
- MinIO instances use SSM for remote management
- No SSH access required for normal operations
- Instances automatically pull latest MinIO version

### Monitoring
- ALB access logs (if enabled)
- MinIO built-in metrics and health checks
- AWS CloudWatch integration via SSM agent

## 🛠️ Troubleshooting

### Common Issues

1. **Instances not joining cluster**
   - Check security group rules allow inter-node communication
   - Verify subnet routing and NAT gateway configuration
   - Check MinIO logs: `journalctl -u minio -f`

2. **ALB health checks failing**
   - Verify security groups allow ALB to reach instances on ports 9000-9001
   - Check MinIO service status on instances
   - Review ALB target group health check configuration

3. **Cannot access MinIO Console**
   - Verify ALB listener rules for /console path
   - Check security groups allow traffic on console port (9001)
   - Confirm certificate configuration if using HTTPS

### Useful Commands

```bash
# Check MinIO service status on instances
aws ssm start-session --target <instance-id>
sudo systemctl status minio

# View MinIO logs
sudo journalctl -u minio -f

# Test MinIO health endpoint
curl http://localhost:9000/minio/health/ready

# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📊 Architecture Diagram

```
Internet
    ↓
[Application Load Balancer] (Public Subnet)
    ↓ (Port 9000/9001)
[MinIO Instance 1] [MinIO Instance 2] [MinIO Instance 3] [MinIO Instance 4]
    ↓ (Private Subnets)
[NAT Gateway] → Internet (for updates, external access)
```

## 🔄 High Availability

- **Multi-AZ deployment**: Resources spread across availability zones
- **Load balancing**: ALB distributes traffic across healthy instances
- **Auto-healing**: Failed instances automatically replaced
- **Data durability**: MinIO erasure coding provides data protection

## 💰 Cost Optimization

- Use NAT Gateway per AZ (can reduce to single NAT Gateway if cost-sensitive)
- Right-size EC2 instances based on workload
- Enable ALB access logs only when needed
- Use gp3 EBS volumes with appropriate IOPS/throughput settings

## 📝 License

This configuration is provided as-is for educational and development purposes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review AWS documentation for relevant services
3. Create an issue in the repository with detailed information
