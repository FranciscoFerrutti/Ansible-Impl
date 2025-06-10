output "bucket_name" {
  value = aws_s3_bucket.this.id
}

data "aws_region" "current" {
  provider = aws.s3
}

output "s3_bucket_url" {
  value = "https://${aws_s3_bucket.this.bucket}.s3.${data.aws_region.current.name}.amazonaws.com/"
}
