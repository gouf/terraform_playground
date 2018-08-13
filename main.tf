provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-940cdceb"
  instance_type = "t2.micro"
  # subnet_id = "subnet-my_vpc_subnet_id"

  tags {
    Name = "terraform-example Server"
  }
}
