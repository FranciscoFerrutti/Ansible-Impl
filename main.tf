#########################################
###             s3 Bucket             ###
#########################################

module "zip_bucket" {
  source = "./modules/s3"

  bucket_name = "zip-bucket"
  bucket_region = "us-east-1"  # Change to your desired region
}

locals {
  zip_1_file_path = "ecommerce-html-template.zip"  # Path to your zip file
  zip_2_file_path = "bootstrap-ecommerce-template.zip"  # Path to your second zip file
}

# Upload the first zip file to the S3 bucket
resource "aws_s3_object" "zip_file_1" {
  bucket = module.zip_bucket.bucket_name
  key    = local.zip_1_file_path
  source = local.zip_1_file_path
  etag   = filemd5(local.zip_1_file_path)
}

# Upload the second zip file to the S3 bucket
resource "aws_s3_object" "zip_file_2" {
  bucket = module.zip_bucket.bucket_name
  key    = local.zip_2_file_path
  source = local.zip_2_file_path
  etag   = filemd5(local.zip_2_file_path)
}

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
  bucket_name = module.zip_bucket.bucket_name  # Pass the S3 bucket name to the EC2 module
  zip_1_file_name = local.zip_1_file_path  # Pass the first zip file name to the EC2 module
  zip_2_file_name = local.zip_2_file_path  # Pass the second zip file name to the EC2 module

  depends_on = [ 
    aws_s3_object.zip_file_1,  # Ensure the first zip file is uploaded before creating EC2 instances
    aws_s3_object.zip_file_2,  # Ensure the second zip file is uploaded before creating EC2 instances
    aws_key_pair.ec2  # Ensure the key pair is created before launching instances
  ]
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

# create extra subnet for vpc master
resource "aws_subnet" "master_extra" {
  vpc_id            = module.vpc["master"].id
  cidr_block        = var.subnet_for_alb.subnet_cidr
  availability_zone = var.subnet_for_alb.availability_zone
  tags = {
    Name = "${var.subnet_for_alb.vpc_name}-extra-subnet"
  }
}

#########################################
###             Key Pair              ###
#########################################

resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  for_each = var.instances
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2" {
  for_each = var.instances

  key_name   = each.value.key_name
  public_key = tls_private_key.ec2[each.key].public_key_openssh

  tags = {
    Name = each.value.key_name
  }
}

resource "local_file" "ssh_key" {
  for_each = var.instances

  content  = tls_private_key.ec2[each.key].private_key_pem
  filename = "${path.module}/${each.value.key_name}.pem"

  # Set permissions to read for the owner only
  file_permission = "0400"
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

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc["master"].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################################
###            Peering                 ###
##########################################

resource "aws_vpc_peering_connection" "peering1" {
  vpc_id = module.vpc["master"].id
  peer_vpc_id = module.vpc["web1"].id
  auto_accept = true
  tags = {
    Name = "Master-Web1-Peering"
  }
}

resource "aws_vpc_peering_connection" "peering2" {
  vpc_id = module.vpc["master"].id
  peer_vpc_id = module.vpc["web2"].id
  auto_accept = true
  tags = {
    Name = "Master-Web2-Peering"
  }
}

resource "aws_vpc_peering_connection" "peering3" {
  vpc_id = module.vpc["master"].id
  peer_vpc_id = module.vpc["web3"].id
  auto_accept = true
  tags = {
    Name = "Master-Web3-Peering"
  }
}

# Route tables for peering connections

resource "aws_route" "master_to_web1" {
  route_table_id            = module.vpc["master"].route_table_id
  destination_cidr_block    = module.vpc["web1"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering1.id
}

resource "aws_route" "master_to_web2" {
  route_table_id            = module.vpc["master"].route_table_id
  destination_cidr_block    = module.vpc["web2"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering2.id
}

resource "aws_route" "master_to_web3" {
  route_table_id            = module.vpc["master"].route_table_id
  destination_cidr_block    = module.vpc["web3"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering3.id
}

resource "aws_route" "web1_to_master" {
  route_table_id            = module.vpc["web1"].route_table_id
  destination_cidr_block    = module.vpc["master"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering1.id
}

resource "aws_route" "web2_to_master" {
  route_table_id            = module.vpc["web2"].route_table_id
  destination_cidr_block    = module.vpc["master"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering2.id
}

resource "aws_route" "web3_to_master" {
  route_table_id            = module.vpc["web3"].route_table_id
  destination_cidr_block    = module.vpc["master"].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering3.id
}

# #########################################
# ###     Application Load Balancer     ###
# #########################################

module "alb" {
  source = "./modules/alb"

  vpc_id = module.vpc["master"].id
  subnet_ids = [aws_subnet.master_extra.id, module.vpc["master"].subnet_ids[0]]
  security_group_ids = [aws_security_group.alb_sg.id]

  target_ip_addresses = [
    module.ec2["web1"].ec2_instance_private_ip,
    module.ec2["web2"].ec2_instance_private_ip,
    module.ec2["web3"].ec2_instance_private_ip
  ]

  depends_on = [ 
    aws_vpc_peering_connection.peering1,
    aws_vpc_peering_connection.peering2,
    aws_vpc_peering_connection.peering3,
    module.ec2
   ]
}

#########################################
###            Lambda Function        ###
#########################################

locals {
  lambda_names = var.lambda_names
  env_vars = {
    "AMI_ID" = var.ami_id
    "TARGET_GROUP_ARN" = module.alb.target_group_arn,
    "SUBNET_1_ID" = module.vpc["web1"].subnet_ids[0],
    "SUBNET_2_ID" = module.vpc["web2"].subnet_ids[0],
    "SUBNET_3_ID" = module.vpc["web3"].subnet_ids[0],
    "SECURITY_GROUP_1_ID" = aws_security_group.ec2["web1"].id,
    "SECURITY_GROUP_2_ID" = aws_security_group.ec2["web2"].id,
    "SECURITY_GROUP_3_ID" = aws_security_group.ec2["web3"].id,
  }
}

module "lambda" {
  for_each = local.lambda_names
  source = "./modules/lambda"

  name = each.key
  handler = each.value.handler
  method = each.value.method
  env_vars = {
    for k in each.value.env_vars : k => local.env_vars[k]
  }
  api_folder = var.api_folder
  
}

########################################
###            API Gateway           ###
########################################

module "api_gw" {
  for_each = var.lambda_names

  source = "./modules/api_gw"
  name = each.key
  lambda_arn  = module.lambda[each.key].arn
  method      = each.value.method
  api_id      = aws_apigatewayv2_api.this.id

  depends_on = [module.lambda]
}

resource "aws_apigatewayv2_api" "this" {
  name           = "http-api"
  protocol_type  = "HTTP"

  cors_configuration {
      allow_origins     = ["*"]
      allow_methods     = ["OPTIONS", "POST"]
      allow_headers     = ["Content-Type", "Authorization"]
    }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}
