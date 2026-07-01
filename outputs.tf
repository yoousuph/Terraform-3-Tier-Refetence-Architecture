output "vpc_id" {
  value = aws_vpc.three-tier-vpc.id
}

output "public_subnets" {
  value = aws_subnet.public-subnet-web[*].id
}

output "app_subnets" {
  value = aws_subnet.private-subnet-app[*].id
}

output "db_subnets" {
  value = aws_subnet.private-subnet-db[*].id
}