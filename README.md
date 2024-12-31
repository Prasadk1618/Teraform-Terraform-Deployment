README: Deploying a Flask Application on AWS EC2 using Terraform

Overview

This repository contains Terraform code to provision AWS infrastructure and deploy a Flask-based HTTP service. The service is hosted on an EC2 instance with access to S3, following the principle of least privilege using an IAM role.

Task Summary

Configured AWS CLI to interact with AWS services.

Installed Terraform to manage the infrastructure as code.

Developed a Flask application named app.py.

Wrote and applied a Terraform script (main.tf) to:

Create IAM roles and policies.

Provision an EC2 instance.

Attach an IAM instance profile.

Configure security groups.

Deploy the Flask application.

Infrastructure Components

AWS Resources Created:

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

Prerequisites

AWS CLI installed and configured.

Terraform CLI installed (v1.5 or later recommended).

Flask application code (app.py) available in the project directory.

SSH key pair created in AWS (kubernet used in this example).

Deployment Steps

1. Clone the Repository

git clone <repository-url>
cd <repository-folder>

2. Update Variables

Edit main.tf to update values such as:

AWS region (ap-south-1 for Mumbai).

Key name (kubernet for SSH access).

3. Initialize Terraform

Run the following command to initialize the Terraform configuration:

terraform init

4. Plan the Deployment

Generate an execution plan to preview the resources that will be created:

terraform plan

5. Apply the Deployment

Provision the infrastructure and deploy the Flask application:

terraform apply

6. Verify the Deployment

Copy the public IP address displayed in the Terraform output.

Access the Flask application in a web browser:

http://<PUBLIC_IP>:5000

Flask Application (app.py)

The Flask application code (app.py) is included in the deployment script. It provides an HTTP service running on port 5000.

Clean Up

To destroy the infrastructure created by this deployment, run:

terraform destroy

Design Decisions

IAM Role: Used an IAM role for the EC2 instance to securely access S3.

Security Groups: Restricted HTTP and SSH access to essential ports.

User Data Script: Automated the installation of Flask and application deployment.

Challenges and Assumptions

Ensuring that the IAM role adheres to the principle of least privilege.

Validating the Flask application runs without manual intervention post-deployment.

Assumes app.py is available in the project directory.

Contact

For any issues or questions, please open a GitHub issue or contact Prasad.
