# Deploying a Flask Application on AWS EC2 using Terraform



### This repository contains Terraform code to provision AWS infrastructure and deploy a Flask-based HTTP service. The service is hosted on an EC2 instance with access to S3, following the principle of least privilege using an IAM role.

### Task Summary

Configured AWS CLI to interact with AWS services.

Installed Terraform to manage the infrastructure as code.

Developed a Flask application named app.py.

Wrote and applied a Terraform script (main.tf) to:

Create IAM roles and policies.

Provision an EC2 instance.

Attach an IAM instance profile.

Configure security groups.

Deploy the Flask application.

### Infrastructure Components

### AWS Resources Created:

IAM Role

Role: EC2-S3-ReadOnly-Role with the policy AmazonS3ReadOnlyAccess attached.

Allows the EC2 instance to access S3 in a read-only capacity.

IAM Instance Profile

Instance profile: ec2-s3-readonly-profile, linked to the IAM role.

EC2 Instance

AMI: ami-021e165d8c4ff761d (Amazon Linux).

Type: t2.micro (Free Tier eligible).

Security Groups configured for HTTP (port 5000) and SSH (port 22) access.

User data script installs Flask and Boto3, and starts the Flask application.

Security Group

Allows HTTP traffic on port 5000 and SSH traffic on port 22 from any IP.

Output

Displays the public IP address of the EC2 instance upon successful deployment.

### Prerequisites

AWS CLI installed and configured.

Terraform CLI installed (v1.5 or later recommended).

Flask application code (app.py) available in the project directory.

SSH key pair created in AWS (kubernet used in this example).

### Deployment Steps

### 1. This Is My app.py Code
```bash
from flask import Flask, jsonify
import boto3

app = Flask(__name__)
s3 = boto3.client('s3')
BUCKET_NAME = 'taskwalibucket'

@app.route('/list-bucket-content/<path:subpath>', methods=['GET'])
@app.route('/list-bucket-content', defaults={'subpath': ''}, methods=['GET'])
def list_bucket_content(subpath):
    prefix = subpath.strip('/') + '/' if subpath else ''
    response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=prefix, Delimiter='/')

    contents = []
    if 'CommonPrefixes' in response:
        contents.extend([cp['Prefix'].rstrip('/') for cp in response['CommonPrefixes']])
    if 'Contents' in response:
        contents.extend([obj['Key'].replace(prefix, '') for obj in response['Contents'] if obj['Key'] != prefix])

    return jsonify({'content': contents})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```
### And This Is My Terraform Deployment Code main.tf
```bash
provider "aws" {
region = "ap-south-1" # Mumbai
}

# Create IAM Role
resource "aws_iam_role" "ec2_s3_readonly" {
  name               = "EC2-S3-ReadOnly-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach S3 ReadOnly Policy to the Role
resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.ec2_s3_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Create an Instance Profile for the IAM Role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-s3-readonly-profile"
  role = aws_iam_role.ec2_s3_readonly.name
}

# EC2 Instance
resource "aws_instance" "http_service" {
  ami           = "ami-021e165d8c4ff761d" # Amazon Linux
  instance_type = "t2.micro"              # Free tier
  key_name      = "kubernet"               # Key name

  security_groups = [aws_security_group.http_access.name]

  # Attach the IAM instance profile
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 pip
              pip3 install flask boto3
              cat <<EOT >> /home/ec2-user/app.py
              ${file("app.py")}
              EOT
              python3 /home/ec2-user/app.py &
              EOF

  tags = {
    Name = "HTTP-Service-Instance"
  }
}

# Security Group
resource "aws_security_group" "http_access" {
  name        = "http-access-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

output "instance_public_ip" {
  value       = aws_instance.http_service.public_ip
  description = "Public IP of the EC2 instance"
}
```

### 2. Update Variables

Edit main.tf to update values such as:

AWS region (ap-south-1 for Mumbai).

Key name (kubernet for SSH access).

### 3. Initialize Terraform

Run the following command to initialize the Terraform configuration:

```bash
terraform init
```
### 4. Plan the Deployment

Generate an execution plan to preview the resources that will be created:
```bash
terraform plan
```
### 5. Apply the Deployment

Provision the infrastructure and deploy the Flask application:
```bash
terraform apply
```
6. Verify the Deployment

Copy the public IP address displayed in the Terraform output.

Access the Flask application in a web browser:
```bash
http://<PUBLIC_IP>:5000
```
### Flask Application (app.py)

The Flask application code (app.py) is included in the deployment script. It provides an HTTP service running on port 5000.

### Clean Up

To destroy the infrastructure created by this deployment, run:
```bash
terraform destroy
```
### Design Decisions

IAM Role: Used an IAM role for the EC2 instance to securely access S3.

Security Groups: Restricted HTTP and SSH access to essential ports.

User Data Script: Automated the installation of Flask and application deployment.

