data "aws_ami" "ubuntu-24-04-lts" {
  # Most recent Ubuntu 24.04 LTS AMI
  most_recent = true
  owners      = ["099720109477"] # Canonical
  # Ubuntu
  # Filter for Ubuntu 24.04 LTS
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-24.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available" {}