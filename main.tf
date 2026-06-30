// Create VPC
resource "aws_vpc" "main-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "three-tier-vpc"
  }
}

// Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

// Create public subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public-sub-web" {
  count = length(var.public_subnets_web)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_web[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-${count.index + 1}"
  }
}

// Create private subnets
resource "aws_subnet" "private-sub-app" {
  count = length(var.private_subnets_app)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_app[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "app-${count.index + 1}"
  }
}

// Create database subnet
resource "aws_subnet" "private-subnet-db" {
  count = length(var.private_subnets_db)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_db[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "db-${count.index + 1}"
  }
}

// Create route tables
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet-gw-rt" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

// Associate public subnet
resource "aws_route_table_association" "public-sub-rt-ass" {
  count = length(var.public_subnets_web)

  subnet_id      = aws_subnet.public-sub-web[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

// Create Elastic IP for NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

//Create NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]
}

// Create private route table
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

// Associate app subnets to the private route table above
resource "aws_route_table_association" "private-app-rt-ass" {
  count = length(var.private_subnets_app)

  subnet_id      = aws_subnet.p[count.index].id
  route_table_id = aws_route_table.private.id
}

// Associate DB subnets
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "db" {
  count = length(var.db_subnets)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

