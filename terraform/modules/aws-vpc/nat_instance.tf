
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat_sg" {
  count = var.enable_nat_instance ? 1 : 0

  vpc_id      = aws_vpc.main_vpc.id
  name_prefix = "nat_sg_"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat_instance" {
  count                       = var.enable_nat_instance ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.nano"
  subnet_id                   = aws_subnet.public_subnets[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nat_sg[0].id]
  source_dest_check           = false

  user_data = <<-EOF
#!/bin/bash
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo iptables --flush
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -A POSTROUTING -o $(ip addr show | awk '/^[0-9]+: en/{gsub(":", ""); print $2; exit}') -s 0.0.0.0/0 -j MASQUERADE
EOF

  tags = {
    Name = "${local.vpc_name}-nat-instance"
  }

  lifecycle {
    ignore_changes = [ami]

    precondition {
      condition     = !(var.enable_nat_gateway && var.enable_nat_instance)
      error_message = "You cannot enable both NAT Gateway and NAT Instance at the same time."
    }
  }
}

resource "aws_route" "nat_instance_route" {
  count                  = var.enable_nat_instance ? 1 : 0
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"

  network_interface_id = aws_instance.nat_instance[0].primary_network_interface_id
}