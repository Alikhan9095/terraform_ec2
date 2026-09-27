Terraform AWS EC2 Deployment This project provisions an Amazon EC2 instance on AWS using Terraform, installs Apache (httpd), and serves a simple web page.

It uses: Remote backend in S3 for Terraform state DynamoDB for state locking Default VPC and subnet Security Group allowing HTTP (port 80)
