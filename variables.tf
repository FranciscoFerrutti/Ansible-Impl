variable "instances" {
  type = map(object({
    key_name          = string
    instance_type          = string
    storage_size  = optional(number)
    storage_type  = optional(string)
    public_ip    = optional(bool, false)
    user_data_path = optional(string, null)
  }))
  default = {
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
      public_ip    = true
      user_data_path = "modules/ec2/user_data/web1.sh"
    }
    web2 = {
      key_name      = "web2"
      instance_type = "t2.micro"
      public_ip    = true
      user_data_path = "modules/ec2/user_data/web2.sh"
    }
    web3 = {
      key_name      = "web3"
      instance_type = "t2.micro"
      public_ip    = true
      user_data_path = "modules/ec2/user_data/web3.sh"
    }
  }
}

variable "vpcs" {
  type = map(object({
    vpc_cidr    = string
    subnet_cidr = string
    availability_zone = string
    public = optional(bool, true)
  }))
  default = {
    master = {
      vpc_cidr    = "10.0.6.0/23"
      subnet_cidr = "10.0.1.0/24"
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
      subnet_cidr = "10.0.0.0/24"
      availability_zone = "us-east-1c"
      public = true
    }
    web3 = {
      vpc_cidr    = "10.0.4.0/23"
      subnet_cidr = "10.0.0.0/24"
      availability_zone = "us-east-1d"
      public = true
    }
  }
}

variable "subnet_for_alb" {
  type = object({
    vpc_cidr          = string
    vpc_name          = string
    subnet_cidr       = string
    availability_zone = string
    subnet_name       = string
    public            = optional(bool, true)
  })
  default = {
    vpc_cidr          = "10.0.6.0/23"
    vpc_name          = "master"
    subnet_cidr       = "10.0.7.0/24"
    availability_zone = "us-east-1b"
    subnet_name       = "master-alb-subnet"
    public            = true
  }
}

variable "lambda_names" {
  type = map(object({
    handler = string
    method  = string
    env_vars = list(string)
  }))
}

variable "api_folder" {
  type = string
  default = "api"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "ami_id" {
  type = string
  default = "ami-084568db4383264d4" # Ubuntu 24.04 LTS
}
