variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB"
  type        = list(string)
}

variable "target_instance_ids" {
  description = "List of EC2 instance IDs to register in target group"
  type        = list(string)
}


