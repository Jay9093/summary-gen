resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  key_name      = aws_key_pair.app_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.public[0].id

  user_data = templatefile("${path.module}/user-data.sh", {
    app_name = var.app_name
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

resource "aws_key_pair" "app_key" {
  key_name   = "${var.app_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
