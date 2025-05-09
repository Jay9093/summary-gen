resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name
  acl    = "private"
}
