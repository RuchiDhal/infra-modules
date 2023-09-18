provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}

locals {
  common_tags = `{
    Stack       = var.stack_name
    Environment = var.environment
  }
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Makes your instances shared on the host.
  instance_tenancy = "default"

  tags = merge(local.common_tags, { Name = var.vpc.name })
}
# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  for_each          = var.vpc.private_subnets
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  vpc_id            = aws_vpc.main.id
  tags              = merge(local.common_tags, { Name = each.key })
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  for_each          = var.vpc.public_subnets
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  vpc_id            = aws_vpc.main.id
  tags              = merge(local.common_tags, { Name = each.key })
}

# Create a NAT gateway for each private subnet to get internet connectivity

locals {
  nat_gateway_subnet = lookup(var.vpc, "nat_gateway_subnet_name", element(keys(aws_subnet.public), 0))
}

resource "aws_nat_gateway" "gateway" {
  subnet_id     = aws_subnet.public[local.nat_gateway_subnet].id
  depends_on    = [aws_subnet.public]
}

# IGW for the public subnet
resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.main.id
}

# By default traffic goes to NAT gateway (are private)
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gateway.id
}

# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet.id
  }

  lifecycle {
    ignore_changes = [
      route
    ]
  }
}
# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}