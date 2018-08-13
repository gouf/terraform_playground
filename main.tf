variable "vpc_id" {
  type    = "string"
  default = "vpc-0a84e4b7d165f8525"
}

variable "vpc_subnet_id" {
  type    = "string"
  default = "subnet-0e498dea8e195959c"
}

variable "ec2_open_port" {
  type    = "string"
  default = "8080"
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_eip" "example_eip" {
  instance = "${aws_instance.example.id}"
  vpc      = true
}

resource "aws_instance" "example" {
  ami           = "ami-940cdceb"
  instance_type = "t2.micro"
  subnet_id     = "${var.vpc_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  tags {
    Name = "terraform-example server"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.ec2_open_port}" &
              EOF
}

resource "aws_security_group" "instance" {
  name ="terraform-example-instance"

  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = "${var.ec2_open_port}"
    to_port     = "${var.ec2_open_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
