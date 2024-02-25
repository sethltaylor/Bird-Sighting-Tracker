resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Bird Tracker VPC"
    }
}

resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnet_cidr) 
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.public_subnet_cidr, count.index)
    availability_zone = element(var.azs, count.index)
    map_public_ip_on_launch = true 

    tags = {
      Name = "Public Subnet ${count.index + 1}"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Bird Tracker VPC IGW"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
    count = length(var.public_subnet_cidr)
    subnet_id = element(aws_subnet.public_subnet[*].id, count.index)
    route_table_id = aws_route_table.second_rt.id
}

resource "aws_security_group" "bird_tracker_sg_tf" {
  name = "bird-tracker-sg-tf"
  description = "Allow traffic in and out of public subnet."
  vpc_id = aws_vpc.main.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
  }
}
