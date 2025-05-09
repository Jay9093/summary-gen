provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.app_name}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.app_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Security group for Flask application"
  vpc_id      = aws_vpc.main.id

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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-sg"
    Environment = var.environment
  }
}

# IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ec2-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.app_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_uploads.arn,
          "${aws_s3_bucket.app_uploads.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  key_name      = "try1"

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.public[0].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user-data.sh", {
    app_name = var.app_name
    github_repo = var.github_repo
    s3_bucket_name = aws_s3_bucket.app_uploads.bucket
    aws_access_key = var.aws_access_key
    aws_secret_key = var.aws_secret_key
    aws_region = var.aws_region
  })

  tags = {
    Name        = "${var.app_name}-server"
    Environment = var.environment
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_key_pair" "try1" {
  key_name   = "try1"
  public_key = file("${path.module}/try1.pub")
}

# S3 Bucket
resource "aws_s3_bucket" "app_uploads" {
  bucket = "${var.app_name}-uploads-${random_string.suffix.result}"

  tags = {
    Name        = "${var.app_name}-uploads"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "app_uploads" {
  bucket = aws_s3_bucket.app_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_uploads" {
  bucket = aws_s3_bucket.app_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
output "app_server_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for file uploads"
  value       = aws_s3_bucket.app_uploads.bucket
}

output "app_url" {
  description = "URL of the application"
  value       = "http://${aws_instance.app_server.public_ip}"
} 