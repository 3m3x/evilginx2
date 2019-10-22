provider "aws" {
  profile = var.aws_profile
  region  = "ap-southeast-2"
}

resource "aws_key_pair" "evilginx2_ssh_key" {
  key_name   = "evilginx2_ssh_key"
  public_key = "${file("${var.ssh_pub_key}")}"
}

resource "aws_vpc" "evilginx2" {
  cidr_block           = "10.10.1.0/24"
  enable_dns_hostnames = true
}

resource "aws_subnet" "evilginx2" {
  vpc_id     = "${aws_vpc.evilginx2.id}"
  cidr_block = "10.10.1.0/24"
}

resource "aws_internet_gateway" "evilginx2" {
  vpc_id = "${aws_vpc.evilginx2.id}"
}

resource "aws_route_table" "evilginx2" {
  vpc_id = "${aws_vpc.evilginx2.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.evilginx2.id}"
  }
}

resource "aws_route_table_association" "evilginx2" {
  subnet_id      = "${aws_subnet.evilginx2.id}"
  route_table_id = "${aws_route_table.evilginx2.id}"
}

resource "aws_security_group" "evilginx2" {
  name   = "evilginx2-ports"
  vpc_id = "${aws_vpc.evilginx2.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "evilginx2" {
  # ap-southeast-2 18.04 LTS "bionic" HVM EBS store
  ami           = "ami-0532935b53d8e05ee"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.evilginx2_ssh_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.evilginx2.id}"
  ]
  subnet_id                   = "${aws_subnet.evilginx2.id}"
  associate_public_ip_address = true

  tags = {
    Name = "evilginx2"
  }
}

# When you specify the remote-exec within the aws_instance block
# Terraform will run that code before the security group is attached
# which is a completely braindead idea because, y'know, ya might need
# freakin Internet access when you're provisioning your instance.
resource "null_resource" "foobar" {
  triggers = {
    public_ip = "${aws_instance.evilginx2.public_ip}"
  }

  # Terraform's ridiculous default approach to ssh'ing into the
  # instance with the root account doesn't play nicely with our
  # Ubuntu AMI, so this:
  connection {
    type  = "ssh"
    host  = "${aws_instance.evilginx2.public_ip}"
    user  = "ubuntu"
    port  = "22"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "wget ${var.package_url}",
      "sudo apt install -y unzip",
      "unzip *.zip",
      "chmod 700 ./install.sh",
      "sudo ./install.sh"
    ]
  }

  provisioner "local-exec" {
    command = "echo -e '\n\nConnect: ssh ubuntu@${aws_instance.evilginx2.public_ip}'"
  }
}

output "ssh-access" {
  value = "ssh ubuntu@${aws_instance.evilginx2.public_ip}"
}
