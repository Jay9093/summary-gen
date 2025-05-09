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
