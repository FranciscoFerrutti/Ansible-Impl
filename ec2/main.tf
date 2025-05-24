#########################################
###            Instancias             ###
#########################################

# Create the EC2 master and web instances
resource "aws_instance" "ec2-demo" {
  for_each = var.instances

  ami                    = data.aws_ami.ubuntu-24-04-lts.id
  instance_type          = each.value.type
  key_name               = aws_key_pair.ec2-demo[each.key].key_name
  vpc_security_group_ids = [aws_security_group.ec2_demo[each.key].id]
  subnet_id              = module.vpc[each.key].public_subnets[0] // <-- Use public subnet

  tags = {
    Name = each.value.name
  }

  root_block_device {
    volume_size           = lookup(each.value, "storage_size", 8)
    volume_type           = lookup(each.value, "storage_type", "gp3")
    delete_on_termination = true
  }
}



#########################################
###            Networking             ###
#########################################

# Create the VPCs
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  for_each = var.vpcs

  name = each.key
  cidr = each.value.vpc_cidr

  azs            = data.aws_availability_zones.available.names
  public_subnets = [for az in data.aws_availability_zones.available.names : "${each.value.subnet_cidr}"]

  enable_nat_gateway      = false
  single_nat_gateway      = false
  enable_internet_gateway = true

  tags = {
    Name = each.key
  }
}


#########################################
###             Key Pair              ###
#########################################

resource "tls_private_key" "ec2-demo" {
  for_each = var.instances
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2-demo" {
  for_each   = var.instances
  key_name   = "${each.value.name}_key_pair"
  public_key = tls_private_key.ec2-demo[each.key].public_key_openssh
}

resource "local_file" "ssh_key" {
  for_each        = var.instances
  filename        = "${aws_key_pair.ec2-demo[each.key].key_name}.pem"
  content         = tls_private_key.ec2-demo[each.key].private_key_pem
  file_permission = "0400"
}


#########################################
###           Security Groups         ###
#########################################
resource "aws_security_group" "ec2_demo" {
  for_each = var.instances

  name        = each.key == "master" ? "SG-MasterServer" : "SG-WebServer${substr(each.key, -1, 1)}"
  description = "Security group for ${each.value.name}"
  vpc_id      = module.vpc[each.key].vpc_id

  // Inbound rules
  dynamic "ingress" {
    for_each = each.key == "master" ? [
      { from_port = 22,   to_port = 22,   protocol = "tcp", description = "SSH" },
      { from_port = 80,   to_port = 80,   protocol = "tcp", description = "HTTP" },
      { from_port = 443,  to_port = 443,  protocol = "tcp", description = "HTTPS" },
      { from_port = 30000, to_port = 32000, protocol = "tcp", description = "Custom TCP" }
    ] : [
      { from_port = 22,   to_port = 22,   protocol = "tcp", description = "SSH" },
      { from_port = 80,   to_port = 80,   protocol = "tcp", description = "HTTP" }
    ]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
      description = ingress.value.description
    }
  }

  // Outbound rule (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = each.key == "master" ? "SG-MasterServer" : "SG-WebServer${substr(each.key, -1, 1)}"
  }
}
