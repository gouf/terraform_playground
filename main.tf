provider "aws" {
  region = "ap-northeast-1"
}

data "aws_availability_zones" "all" {}

#
# VPC
#
resource "aws_vpc" "terraforn_playground" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-playground-vpc"
  }
}

resource "aws_route_table" "rt_a" {
  vpc_id = "${aws_vpc.terraforn_playground.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_a.id}"
  }
}

resource "aws_route_table_association" "rta_a" {
  subnet_id      = "${aws_subnet.subnet_a.id}"
  route_table_id = "${aws_route_table.rt_a.id}"
}

resource "aws_internet_gateway" "igw_a" {
  vpc_id = "${aws_vpc.terraforn_playground.id}"
  tags {
    Name = "terraforn_playground"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id      = "${aws_vpc.terraforn_playground.id}"
  cidr_block = "10.0.6.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform_subnet_1a"
  }
}


#
# Autoscale and ELB
#
resource "aws_launch_configuration" "example" {
  image_id        = "ami-940cdceb"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}", "${aws_security_group.elb.id}"]
  key_name        = "ec2"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx
EOF
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1d"]
  vpc_zone_identifier = ["${aws_subnet.subnet_a.id}"]

  load_balancers      = ["${aws_elb.example.name}"]
  health_check_type   = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name               = "terraform-asg-example"
  security_groups    = ["${aws_security_group.elb.id}", "${aws_security_group.instance.id}"]
  subnets            = ["${aws_subnet.subnet_a.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_protocol = "http"
    instance_port     = 80
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 60
    target              = "HTTP:80/"
  }
}

#
# Security groups
#
resource "aws_security_group" "instance" {
  name ="terraform-example-instance"

  vpc_id = "${aws_vpc.terraforn_playground.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  vpc_id = "${aws_vpc.terraforn_playground.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
