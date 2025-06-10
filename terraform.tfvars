instances = {
  master = {
    key_name      = "master"
    instance_type = "t2.large"
    storage_size  = 20
    storage_type  = "gp3"
    public_ip    = true
    user_data_path = "modules/ec2/user_data/master.sh"
  }
  web1 = {
    key_name      = "web1"
    instance_type = "t2.micro"
    storage_size  = 8
    storage_type  = "gp3"
    public_ip    = true
    user_data_path = "modules/ec2/user_data/web1.sh"
  }
  web2 = {
    key_name      = "web2"
    instance_type = "t2.micro"
    storage_size  = 8
    storage_type  = "gp3"
    public_ip    = true
    user_data_path = "modules/ec2/user_data/web2.sh"
  }
  web3 = {
    key_name      = "web3"
    instance_type = "t2.micro"
    storage_size  = 8
    storage_type  = "gp3"
    public_ip    = true
    user_data_path = "modules/ec2/user_data/web3.sh"
  }
}

vpcs = {
  master = {
    vpc_cidr    = "10.0.6.0/23"
    subnet_cidr = "10.0.6.0/24"
    availability_zone = "us-east-1a"
    public = true
  }
  web1 = {
    vpc_cidr    = "10.0.0.0/23"
    subnet_cidr = "10.0.0.0/24"
    availability_zone = "us-east-1b"
    public = true
  }
  web2 = {
    vpc_cidr    = "10.0.2.0/23"
    subnet_cidr = "10.0.2.0/24"
    availability_zone = "us-east-1c"
    public = true
  }
  web3 = {
    vpc_cidr    = "10.0.4.0/23"
    subnet_cidr = "10.0.4.0/24"
    availability_zone = "us-east-1d"
    public = true
  }
}

lambda_names = {
  "terminate_ec2" = {
    handler = "terminate_ec2.lambda_handler"
    method = "POST"
    env_vars = [
      
    ]
  }
  "launch_ec2" = {
    handler = "launch_ec2.lambda_handler"
    method = "POST"
    env_vars = [
      "AMI_ID"
    ]
  }
}

