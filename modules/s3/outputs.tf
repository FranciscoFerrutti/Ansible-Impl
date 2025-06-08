output "bucket_name" {
  value = aws_s3_bucket.this.id
}

data "aws_region" "current" {
  provider = aws.s3
}
