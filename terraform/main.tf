provider "aws" {
  region = "us-east-1"  # Change this to your preferred region
}

# S3 bucket for file uploads
resource "aws_s3_bucket" "app_uploads" {
  bucket = "flask-app-uploads-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "app_uploads" {
  bucket = aws_s3_bucket.app_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS
  instance_type = "t2.micro"
  key_name      = aws_key_pair.app_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip python3-venv nginx
              pip3 install gunicorn
              EOF

  tags = {
    Name = "Flask-App-Server"
  }
}

# Security group
resource "aws_security_group" "app_sg" {
  name        = "flask-app-sg"
  description = "Security group for Flask application"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH key pair
resource "aws_key_pair" "app_key" {
  key_name   = "flask-app-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Make sure you have this file
}

# Random string for unique bucket name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Output the EC2 instance public IP
output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}

# Output the S3 bucket name
output "s3_bucket_name" {
  value = aws_s3_bucket.app_uploads.bucket
} 