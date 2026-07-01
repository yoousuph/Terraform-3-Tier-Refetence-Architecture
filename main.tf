// ----------- VPC ----------------

// Create VPC
resource "aws_vpc" "three-tier-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "three-tier-vpc"
  }
}

// ------------- SUBNETS --------------

//PUBLIC SUBNET FOR WEB TIER
// Create public subnets for web tier
data "aws_availability_zones" "az" {}

resource "aws_subnet" "public-subnet-web" {
  count = length(var.public_subnets_web_cidr)

  vpc_id                  = aws_vpc.three-tier-vpc.id
  cidr_block              = var.public_subnets_web_cidr[count.index]
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-sub-web${count.index + 1}"
  }
}

// PRIVATE SUBNET FOR APP TIER
// Create private subnets for app tier
resource "aws_subnet" "private-subnet-app" {
  count = length(var.private_subnets_app_cidr)

  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = var.private_subnets_app_cidr[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "private-sub-app${count.index + 1}"
  }
}

// PRIVATE SUBNET FOR DB TIER
// Create private subnet for db tier
resource "aws_subnet" "private-subnet-db" {
  count = length(var.private_subnets_db_cidr)

  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = var.private_subnets_db_cidr[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "private-subnet-db${count.index + 1}"
  }
}

// -------------- INTERNET GATEWAY ------------------
// Create internet gateway
resource "aws_internet_gateway" "three-tier-vpc-igw" {
  vpc_id = aws_vpc.three-tier-vpc.id

  tags = {
    Name = "three-tier-vpc-igw"
  }
}

// ---------- NAT GATEWAY -------------

// Create Elastic IP for NAT gateway
resource "aws_eip" "nat-gw-eip" {
  domain = "vpc"
}

//Create NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-gw-eip.id
  subnet_id     = aws_subnet.private-subnet-app[0].id

  depends_on = [
    aws_internet_gateway.three-tier-vpc-igw
  ]
}

// ----------- ROUTE TABLE & ROUTES ------------------

// --------- PUBLIC ROUTE ---------------------
// Create secondary route table
resource "aws_route_table" "secondary-rt" {
  vpc_id = aws_vpc.three-tier-vpc.id

  tags = {
    Name = "secondary-rt"
  }
}

// Add internet gateway route to the secondary route table
resource "aws_route" "internet-gw-route" {
  route_table_id         = aws_route_table.secondary-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.three-tier-vpc-igw.id
}

// Associate web tier subnets with the secondary route table
resource "aws_route_table_association" "web-private_subnets_app_cidr-ass" {
  count = length(var.public_subnets_web_cidr)

  subnet_id      = aws_subnet.public-subnet-web[count.index].id
  route_table_id = aws_route_table.secondary-rt.id
}

// ------------ PRIVATE ROUTE ---------------
// Create main route table
resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.three-tier-vpc.id

  tags = {
    Name = "main-rt"
  }
}

// Add nat gateway route to the main route table
resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.main-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
}

// Associate app subnets to the private route table above
resource "aws_route_table_association" "private-subnet-app-rt-ass" {
  count = length(var.private_subnets_app_cidr)

  subnet_id      = aws_subnet.private-subnet-app[count.index].id
  route_table_id = aws_route_table.main-rt.id
}

