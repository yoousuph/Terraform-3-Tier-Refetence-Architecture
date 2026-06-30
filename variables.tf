variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_web_cidr" {
  default = [
    "10.0.0.0/24",
    "10.0.10.0/24"
  ]
}

variable "private_subnets_app_cidr" {
  default = [
    "10.0.15.0/24",
    "10.0.20.0/24"
  ]
}

variable "private_subnets_db_cidr" {
  default = [
    "10.0.25.0/24",
    "10.0.30.0/24"
  ]
}