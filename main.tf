# Variables for configurationssssssssssssssssssssss
variable "hongkong_vpc_cidr" {
  description = "CIDR block for the Region 2 VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "tokyo_vpc_id" {
  description = "ID of the existing Region 1 VPC"
  type        = string
  default     = "vpc-039181ece9d979587"
}

# Configure AWS providers for both regions
provider "aws" {
  alias  = "tokyo"
  region = "xx-region-1"
}

provider "aws" {
  alias  = "hongkong"
  region = "xx-region-2"
}

# Reference existing Region 1 VPC
data "aws_vpc" "tokyo_vpc" {
  provider = aws.tokyo
  id       = var.tokyo_vpc_id
}

# Create new Region 2 VPC
resource "aws_vpc" "hongkong_vpc" {
  provider                         = aws.hongkong
  cidr_block                       = var.hongkong_vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
  
  tags = {
    Name = "etc-hongkong"
  }
}

# Create subnet for Region 2 VPC
resource "aws_subnet" "hongkong_subnet" {
  provider                = aws.hongkong
  vpc_id                  = aws_vpc.hongkong_vpc.id
  cidr_block              = cidrsubnet(var.hongkong_vpc_cidr, 8, 1)  # Creates a /24 subnet from the VPC CIDR
  availability_zone       = "xx-region-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "etc-hongkong-subnet"
  }
}

# Get all route tables for Region 1 VPC
data "aws_route_tables" "tokyo_route_tables" {
  provider = aws.tokyo
  vpc_id   = data.aws_vpc.tokyo_vpc.id
}

# Create main route table for Region 2 VPC
resource "aws_route_table" "hongkong_route_table" {
  provider = aws.hongkong
  vpc_id   = aws_vpc.hongkong_vpc.id
  
  tags = {
    Name = "etc-hongkong-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "hongkong_route_association" {
  provider       = aws.hongkong
  subnet_id      = aws_subnet.hongkong_subnet.id
  route_table_id = aws_route_table.hongkong_route_table.id
}

# Create VPC Peering Connection
resource "aws_vpc_peering_connection" "tokyo_hongkong_peering" {
  provider      = aws.tokyo
  vpc_id        = data.aws_vpc.tokyo_vpc.id
  peer_vpc_id   = aws_vpc.hongkong_vpc.id
  peer_region   = "xx-region-2"
  auto_accept   = false
  
  tags = {
    Name = "Region 1-HongKong-VPC-Peering"
  }
}

# Accept VPC peering connection in Region 2 region
resource "aws_vpc_peering_connection_accepter" "hongkong_accepter" {
  provider                  = aws.hongkong
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_hongkong_peering.id
  auto_accept               = true
  
  tags = {
    Name = "HongKong-Region 1-VPC-Peering-Accepter"
  }
}

# Create route to Region 2 VPC from Region 1 VPC
resource "aws_route" "tokyo_to_hongkong" {
  provider                  = aws.tokyo
  count                     = length(data.aws_route_tables.tokyo_route_tables.ids)
  route_table_id            = data.aws_route_tables.tokyo_route_tables.ids[count.index]
  destination_cidr_block    = var.hongkong_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_hongkong_peering.id
}

# Create route to Region 1 VPC from Region 2 VPC
resource "aws_route" "hongkong_to_tokyo" {
  provider                  = aws.hongkong
  route_table_id            = aws_route_table.hongkong_route_table.id
  destination_cidr_block    = data.aws_vpc.tokyo_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_hongkong_peering.id
}

# Output the VPC peering connection ID and other useful information
output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.tokyo_hongkong_peering.id
}

output "tokyo_vpc_id" {
  value = data.aws_vpc.tokyo_vpc.id
}

output "hongkong_vpc_id" {
  value = aws_vpc.hongkong_vpc.id
}

output "hongkong_subnet_id" {
  value = aws_subnet.hongkong_subnet.id
}
