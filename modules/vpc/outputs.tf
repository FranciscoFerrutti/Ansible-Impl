output "subnet_ids" {
  value = [
    for k, v in aws_subnet.this : v.id
  ]
}

output "id" {
  value = aws_vpc.this.id
}

output "route_table_id" {
  value = aws_route_table.this.id
}

output "subnet_cidrs" {
  value = [
    for k, v in aws_subnet.this : v.cidr_block
  ]
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
