resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  security_groups        = [aws_security_group.app_sg.name]
  user_data              = file("user_data.sh")

  tags = {
    Name = "AppServer"
  }
}
