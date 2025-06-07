instances = {
  master = {
    name         = "master"
    type         = "t2.large"
    storage_size = 20
    storage_type = "gp3"
  }
  web1 = {
    name = "web1"
    type = "t2.micro"
  }
  web2 = {
    name = "web2"
    type = "t2.micro"
  }
  web3 = {
    name = "web3"
    type = "t2.micro"
  }
}

vpcs = {
  master = {
    name        = "master"
    vpc_cidr    = "10.0.6.0/20"
    subnet_cidr = "10.0.1.0/24"
  }
  web1 = {
    name        = "web1"
    vpc_cidr    = "10.0.0.0/20"
    subnet_cidr = "10.0.0.0/24"
  }
  web2 = {
    name        = "web2"
    vpc_cidr    = "10.0.2.0/20"
    subnet_cidr = "10.0.0.0/24"
  }
  web3 = {
    name        = "web3"
    vpc_cidr    = "10.0.4.0/20"
    subnet_cidr = "10.0.0.0/24"
  }
}
