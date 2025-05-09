variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-0c55b159cbfafe1f0"  # Update with the latest Amazon Linux 2 AMI ID for your region
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "bucket_name" {
  type    = string
  default = "your-unique-bucket-name"  # Ensure this is globally unique
}
