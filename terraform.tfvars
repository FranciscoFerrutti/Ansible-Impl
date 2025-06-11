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

subnet_for_alb = {
  vpc_cidr          = "10.0.6.0/23"
  vpc_name          = "master"
  subnet_cidr       = "10.0.7.0/24"
  availability_zone = "us-east-1b"
  subnet_name       = "master-alb-subnet"
  public            = true
}

lambda_names = {
  "terminate_ec2" = {
    handler = "terminate_ec2.terminate_ec2_handler"
    method = "POST"
    env_vars = [
      
    ]
  }
  "launch_ec2" = {
    handler = "launch_ec2.launch_ec2_handler"
    method = "POST"
    env_vars = [
      "AMI_ID",
      "TARGET_GROUP_ARN",
      "SUBNET_1_ID",
      "SUBNET_2_ID",
      "SUBNET_3_ID",
      "SECURITY_GROUP_1_ID",
      "SECURITY_GROUP_2_ID",
      "SECURITY_GROUP_3_ID",
    ]
  }
}

