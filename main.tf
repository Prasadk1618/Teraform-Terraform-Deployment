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
