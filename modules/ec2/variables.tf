variable "key_name" {
  type        = string
  description = "The name of the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "The type of the EC2 instance"
}

variable "storage_size" {
  type        = number
  description = "The size of the storage volume in GB"
  default     = 8
}

variable "storage_type" {
  type        = string
  description = "The type of the storage volume"
  default     = "gp3"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the EC2 instance will be launched"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to associate with the EC2 instance"
}

variable "public_ip" {
  type        = bool
  description = "Whether to assign a public IP address to the EC2 instance"
  default     = false
}

variable "user_data_path" {
  type        = string
  description = "Path to the user data script for the EC2 instance"
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for getting the HTML template"
}

variable "zip_1_file_name" {
  type        = string
  description = "Name of the first zip file to be uploaded to S3"
}

variable "zip_2_file_name" {
  type        = string
  description = "Name of the second zip file to be uploaded to S3"
}
