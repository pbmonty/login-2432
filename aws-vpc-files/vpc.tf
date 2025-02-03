resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "awsvpc"
  }
}

# Frontend Subnet
resource "aws_subnet" "fsubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "login-fsubnet"
  }
}