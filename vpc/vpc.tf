variable "cidr" {
  type = string
  description = "(optional) describe your variable"
}
variable "cidr_pub" {
  type = string
  description = "(optional) describe your variable"
}
variable "cidr_priv" {
  type = string
  description = "(optional) describe your variable"
}



resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
}


resource "aws_subnet" "pub" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = var.cidr_pub
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pub"
  }
}

resource "aws_subnet" "priv" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = var.cidr_priv

  tags = {
    Name = "priv"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  
  tags = {
    Name = "igw_route"
  }
}

resource "aws_route_table_association" "assoc_pub_subnet" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.igw.id
}


resource "aws_eip" "nat" {
 depends_on=[ aws_internet_gateway.gw ]
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.pub.id}"

  tags = {
    Name = "gw NAT"
  }
}


resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    Name = "nat_route"
  }
}
resource "aws_route_table_association" "assoc_nat_subnet" {
  subnet_id      = aws_subnet.priv.id
  route_table_id = aws_route_table.nat.id
}




//SECURITY GROUPS

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "allow_sg_mysql" {
  name        = "allow_sg_mysql"
  description = "Allow mysql and bastion host traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "ssh from bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.allow_http.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_mysql"
  }
}


output "sub_pub" {
  value = aws_subnet.pub
}

output "sub_priv" {
  value = aws_subnet.priv
}

output "sg_wp" {
  value = aws_security_group.allow_http
}

output "sg_mysql" {
  value = aws_security_group.allow_sg_mysql
}
