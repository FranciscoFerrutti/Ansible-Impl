# append to the bucket_url the /ecommerce_1/ path
output "static_web_A_bucket_url" {
  value = "${module.zip_bucket.s3_bucket_url}${local.zip_1_file_path}"
}

output "static_web_B_bucket_url" {
  value = "${module.zip_bucket.s3_bucket_url}${local.zip_2_file_path}"
}

output "subnet_web1_id" {
  value = module.vpc["web1"].subnet_ids[0]
}

output "subnet_web2_id" {
  value = module.vpc["web2"].subnet_ids[0]
}

output "subnet_web3_id" {
  value = module.vpc["web3"].subnet_ids[0]
}

output "api_gw_launch_url" {
  value = "${aws_apigatewayv2_api.this.api_endpoint}/${aws_apigatewayv2_stage.this.name}/launch_ec2"
  description = "API Gateway URL for launching EC2 instances"
}

output "api_gw_terminate_url" {
  value = "${aws_apigatewayv2_api.this.api_endpoint}/${aws_apigatewayv2_stage.this.name}/terminate_ec2"
  description = "API Gateway URL for terminating EC2 instances"
}

output "master_public_ip" {
  value = module.ec2["master"].ec2_instance_public_ip
  description = "Public IP address of the master EC2 instance"
}

output "web1_public_ip" {
  value = module.ec2["web1"].ec2_instance_public_ip
  description = "Public IP address of the web1 EC2 instance"
}

output "web2_public_ip" {
  value = module.ec2["web2"].ec2_instance_public_ip
  description = "Public IP address of the web2 EC2 instance"
}

output "web3_public_ip" {
  value = module.ec2["web3"].ec2_instance_public_ip
  description = "Public IP address of the web3 EC2 instance"
}

output "web1_private_ip" {
  value = module.ec2["web1"].ec2_instance_private_ip
  description = "Private IP address of the web1 EC2 instance"
}

output "web2_private_ip" {
  value = module.ec2["web2"].ec2_instance_private_ip
  description = "Private IP address of the web2 EC2 instance"
}

output "web3_private_ip" {
  value = module.ec2["web3"].ec2_instance_private_ip
  description = "Private IP address of the web3 EC2 instance"
}

output "web1_instance_id" {
  value = module.ec2["web1"].ec2_instance_id
  description = "Instance ID of the web1 EC2 instance"
}

output "web2_instance_id" {
  value = module.ec2["web2"].ec2_instance_id
  description = "Instance ID of the web2 EC2 instance"
}

output "web3_instance_id" {
  value = module.ec2["web3"].ec2_instance_id
  description = "Instance ID of the web3 EC2 instance"
}
