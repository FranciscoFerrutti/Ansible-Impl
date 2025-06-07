#########################################
###            Instancias             ###
#########################################

# Create the EC2 master and web instances
module "ec2" {
  source = "./modules/ec2"
  for_each = var.instances
  key_name = each.value.key_name
  instance_type = each.value.instance_type

  storage_size = lookup(each.value, "storage_size", 8)  # Default to 8 if not specified
  storage_type = lookup(each.value, "storage_type", "gp3")  # Default to "gp3" if not specified

  subnet_id = module.vpc[each.key].subnet_ids[0]  # Use the first subnet ID from the VPC module
  vpc_security_group_ids = [aws_security_group.ec2[each.key].id]

  public_ip = lookup(each.value, "public_ip", false)  # Default to false if not specified
  user_data_path = lookup(each.value, "user_data_path", "")  # Default to empty if not specified
}



#########################################
###            Networking             ###
#########################################

# Create the VPCs
module "vpc" {
  source = "./modules/vpc"

  for_each = var.vpcs
  vpc_cidr    = each.value.vpc_cidr
  vpc_name    = each.key
  subnets = [
    {
      cidr_block        = each.value.subnet_cidr
      availability_zone = each.value.availability_zone
      name              = "${each.key}-subnet"
      public            = each.value.public
    }
  ]
}

#########################################
###             Key Pair              ###
#########################################

resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2" {
  key_name   = "aws_key_pair"
  public_key = tls_private_key.ec2.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.ec2.key_name}.pem"
  content  = tls_private_key.ec2.private_key_pem
  file_permission = "0600" # Set file permission to read/write for the owner only
}

#########################################
###           Security Groups         ###
#########################################
resource "aws_security_group" "ec2" {
  for_each = var.instances

  name        = each.key == "master" ? "SG-MasterServer" : "SG-WebServer${substr(each.key, -1, 1)}"
  description = "Security group for ${each.value.key_name}"
  vpc_id      = module.vpc[each.key].id

  // Inbound rules
  dynamic "ingress" {
    for_each = each.key == "master" ? [
      { from_port = 22,   to_port = 22,   protocol = "tcp", description = "SSH" },
      { from_port = 80,   to_port = 80,   protocol = "tcp", description = "HTTP" },
      { from_port = 443,  to_port = 443,  protocol = "tcp", description = "HTTPS" },
      { from_port = 30000, to_port = 32000, protocol = "tcp", description = "Custom TCP" } # TODO: Adjust ports
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
