resource "aws_eip" "nat_eip" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}
resource "aws_nat_gateway" "nat_gateway" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnets[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.vpc_name}-nat-gateway"
  }
}
resource "aws_route" "nat_gateway_route" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
}