provider "aws" {
  region  = "ap-south-1"
  profile = "rohan"	
}
resource "aws_key_pair" "terrakey" {
  key_name   = "terrakey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtsmw2UBWuXtxnaG8vKYSvyO1h7/ecGy+IQ9potLJOjP0NG5F13JCMbJRNYRoez9wW2iKDh3riSbP7JHoMG5IGoDXWmHunB1GUxPCDetK4p4mlJj700BA5mfMR8CRMkN1Xn2lvzFh9fKgt2XOoFkF5yH1jqLwy7Nyjv+ayZDmtbW6yqvj7MzNohDcetucZTIpD2Zlxjkd3T+bZcHjl7CqeOzjpn7hbcxojvQvHpTzeeH2jY5q/C3TQJgCEuC7bxCF5dMEVErhXVK8SR0EyhrZg2xbzdMWN/Q6BxaAsQnOMoSTAX3Q+4z9KdRxDcDPjeR97sUk3ShWBUG9QkyVJj+4fQ== rsa-key-20200611"
}

// Modules


module "vpc" {
    source="./vpc"
    cidr = var.cidr_vpc
    cidr_pub = var.cidr_pub
    cidr_priv = var.cidr_priv
}



resource "aws_instance" "wp" {
  depends_on=[module.vpc]
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name = "terrakey"
  subnet_id = module.vpc.sub_pub.id
  associate_public_ip_address = true
  security_groups = [ module.vpc.sg_wp.id ,]
tags = {
    Name = "wp_bastion_host"
}
}
output "osip" {
	value=aws_instance.wp.public_ip
}

resource "aws_instance" "mysql" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "terrakey"
  subnet_id = module.vpc.sub_priv.id
  security_groups = [ module.vpc.sg_mysql.id ,]
tags = {
    Name = "mysql_priv"
}
}

