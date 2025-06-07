resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu-24-04-lts.id

  key_name = var.key_name
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = templatefile(var.user_data_path, {
    # html_content =
  })

  associate_public_ip_address = var.public_ip

}

resource "aws_ebs_volume" "this" {
  availability_zone = aws_instance.this.availability_zone
  size              = var.storage_size
  type              = var.storage_type

  tags = {
    Name = "${var.key_name}-volume"
  }
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.this.id
  instance_id = aws_instance.this.id
}
