data "aws_availability_zones" "availability_zones" {
  state = "available"
}

locals {
  vpc_name        = var.name
  unsupported_azs = ["us-east-1e"]
  total_azs       = length(data.aws_availability_zones.availability_zones.names)
  azs_to_use = slice([
    for az in data.aws_availability_zones.availability_zones.names : az
    if !contains(local.unsupported_azs, az)
  ], 0, min(3, local.total_azs))

  count_azs = length(local.azs_to_use)

  all_19_subnets = [for i in range(local.count_azs * 2) : cidrsubnet(var.cidr_block, 3, i + 1)]

  # Assign one /19 subnet for each AZ to be used for private subnets
  private_subnet_cidrs = slice(local.all_19_subnets, 0, local.count_azs)

  public_network_cidrs = slice(local.all_19_subnets, local.count_azs, local.count_azs * 2)
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(local.public_network_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = element(local.public_network_cidrs, count.index)
  availability_zone = element(local.azs_to_use, count.index)

  tags = {
    Name = "${local.vpc_name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(local.private_subnet_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = element(local.private_subnet_cidrs, count.index)
  availability_zone = element(local.azs_to_use, count.index)

  tags = {
    Name = "${local.vpc_name}-private-${count.index + 1}"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.vpc_name}-rtb"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.vpc_name}-igw"
  }
}

resource "aws_route" "ig_route" {
  route_table_id         = aws_route_table.second_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets, count.index).id
  route_table_id = aws_route_table.second_rt.id
}