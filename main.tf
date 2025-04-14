terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87.0"
    }
  }
}
provider "aws" {
  region = "us-west-1"
}
data "aws_ami" "this" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "main" {
  default = true
}
resource "aws_key_pair" "key" {
  key_name   = "mykey1"
  public_key = file("./aws.pub")
}
resource "aws_instance" "main" {
  ami             = data.aws_ami.this.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key.key_name
  security_groups = [aws_security_group.main.name]
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> public.ip"
  }
}
locals {
  allowed_ports = {
    ssh = {
      direction = "ingress"
      f_port    = 22
      t_port    = 22
      protocol  = "tcp"
      cidr      = "54.193.78.148/32"
    }
    http = {
      direction = "ingress"
      f_port    = 80
      t_port    = 80
      protocol  = "tcp"
      cidr      = "0.0.0.0/0"
    }
    https = {
      direction = "ingress"
      f_port    = 443
      t_port    = 443
      protocol  = "tcp"
      cidr      = "0.0.0.0/0"
    }
    all = {
      direction = "egress"
      f_port    = 0
      t_port    = 65535
      protocol  = "-1"
      cidr      = "0.0.0.0/0"
    }
  }
}
resource "aws_security_group" "main" {
  vpc_id = data.aws_vpc.main.id
  name   = "mysg"
}
resource "aws_security_group_rule" "main1" {
  for_each          = local.allowed_ports
  type              = each.value.direction
  from_port         = each.value.f_port
  to_port           = each.value.t_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.main.id
}
output "public_ip" {
  value = aws_instance.main.public_ip
}


