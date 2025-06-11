resource "aws_instance" "this" {
  ami = "ami-084568db4383264d4" # Ubuntu 24.04 LTS

  key_name = var.key_name
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = templatefile(var.user_data_path, {
    bucket_name = var.bucket_name
    aws_region      = data.aws_region.current.name
    zip_1_file_name   = var.zip_1_file_name
    zip_2_file_name   = var.zip_2_file_name
  })

  associate_public_ip_address = var.public_ip

  root_block_device {
    volume_type = var.storage_type
    volume_size = var.storage_size
    delete_on_termination = true
  }

  tags = {
    Name = var.key_name
  }

}

data "aws_region" "current" {}
