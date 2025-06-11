output "s3_bucket_url" {
  value = module.zip_bucket.s3_bucket_url
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
