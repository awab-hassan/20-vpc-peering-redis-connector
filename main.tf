provider "aws" {
  alias  = "region1"
  region = "xx-region-1"
}

provider "aws" {
  alias  = "region2"
  region = "xx-region-2"
}

# Reference existing Region 1 VPC
data "aws_vpc" "region1_vpc" {
  provider = aws.region1
  id       = var.region1_vpc_id
}

# Create new Region 2 VPC
resource "aws_vpc" "region2_vpc" {
  provider                         = aws.region2
  cidr_block                       = var.region2_vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
  
  tags = {
    Name = "etc-region2"
  }
}

# Create subnet for Region 2 VPC
resource "aws_subnet" "region2_subnet" {
  provider                = aws.region2
  vpc_id                  = aws_vpc.region2_vpc.id
  cidr_block              = cidrsubnet(var.region2_vpc_cidr, 8, 1)  # Creates a /24 subnet from the VPC CIDR
  availability_zone       = "xx-region-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "etc-region2-subnet"
  }
}

# Get all route tables for Region 1 VPC
data "aws_route_tables" "_route_tables" {
  provider = aws.region1
  vpc_id   = data.aws_vpc.region1_vpc.id
}

# Create main route table for Region 2 VPC
resource "aws_route_table" "region2_route_table" {
  provider = aws.region2
  vpc_id   = aws_vpc.region2_vpc.id
  
  tags = {
    Name = "etc-region2-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "region2_route_association" {
  provider       = aws.region2
  subnet_id      = aws_subnet.region2_subnet.id
  route_table_id = aws_route_table.region2_route_table.id
}

# Create VPC Peering Connection
resource "aws_vpc_peering_connection" "region1_region2_peering" {
  provider      = aws.region1
  vpc_id        = data.aws_vpc.region1_vpc.id
  peer_vpc_id   = aws_vpc.region2_vpc.id
  peer_region   = "xx-region-2"
  auto_accept   = false
  
  tags = {
    Name = "Region 1-region2-VPC-Peering"
  }
}

# Accept VPC peering connection in Region 2 region
resource "aws_vpc_peering_connection_accepter" "region2_accepter" {
  provider                  = aws.region2
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_region2_peering.id
  auto_accept               = true
  
  tags = {
    Name = "region2-Region 1-VPC-Peering-Accepter"
  }
}

# Create route to Region 2 VPC from Region 1 VPC
resource "aws_route" "region1_to_region2" {
  provider                  = aws.region1
  count                     = length(data.aws_route_tables.region1_route_tables.ids)
  route_table_id            = data.aws_route_tables.region1_route_tables.ids[count.index]
  destination_cidr_block    = var.region2_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_region2_peering.id
}

# Create route to Region 1 VPC from Region 2 VPC
resource "aws_route" "region2_to_region1" {
  provider                  = aws.region2
  route_table_id            = aws_route_table.region2_route_table.id
  destination_cidr_block    = data.aws_vpc.region1_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_region2_peering.id
}

# Output the VPC peering connection ID and other useful information
output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.region1_region2_peering.id
}

output "region1_vpc_id" {
  value = data.aws_vpc.region1_vpc.id
}

output "region2_vpc_id" {
  value = aws_vpc.region2_vpc.id
}

output "region2_subnet_id" {
  value = aws_subnet.region2_subnet.id
}
