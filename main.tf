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
  subnet_id     = "subnet-0e498dea8e195959c"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  tags {
    Name = "terraform-example server"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_security_group" "instance" {
  name ="terraform-example-instance"

  vpc_id = "vpc-0a84e4b7d165f8525"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
