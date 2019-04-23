// Provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "us-west-2"
}


// VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "jldiamon-vpc"
  }
}


// Subnets
resource "aws_subnet" "public-2a" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "jldiamon-public-2a"
  }
}

resource "aws_subnet" "public-2b" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "jldiamon-public-2b"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "jldiamon-private"
  }
}


// Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "jldiamon-igw"
  }
}


// NAT gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.ngw_eip.id}"
  subnet_id     = "${aws_subnet.public-2a.id}"
  tags = {
    Name = "jldiamon-ngw"
  }
}


// Elastic IPs
resource "aws_eip" "ngw_eip" {
  vpc      = true

  tags = {
    Name = "jldiamon-ngw_eip"
  }
}

resource "aws_eip" "bastion_eip" {
  vpc      = true
  instance = "${aws_instance.bastion.id}"

  tags = {
    Name = "jldiamon-bastion_eip"
  }
}


// Security groups
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Load balancer security group"
  vpc_id      = "${aws_vpc.main.id}"

  tags = {
    Name = "jldiamon-lb_sg"
  }

}

resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "Web app security group"
  vpc_id      = "${aws_vpc.main.id}"

  tags = {
    Name = "jldiamon-web_app_sg"
  }

}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Bastion host security group"
  vpc_id      = "${aws_vpc.main.id}"

  tags = {
    Name = "jldiamon-bastion_sg"
  }

}

resource "aws_security_group" "basic_sg" {
  name        = "basic_sg"
  description = "Allow outbound HTTP/HTTPS"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jldiamon-basic_sg"
  }

}


// Security group rules (broken out to avoid cyclic dependency issues)
resource "aws_security_group_rule" "lb_ingress" {
  type = "ingress"
  security_group_id = "${aws_security_group.lb_sg.id}"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_egress" {
  type = "egress"
  security_group_id = "${aws_security_group.lb_sg.id}"
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.web_app_sg.id}"
}

resource "aws_security_group_rule" "web_app_ingress_http" {
  type = "ingress"
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "web_app_ingress_ssh" {
  type = "ingress"
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.bastion_sg.id}"
}

resource "aws_security_group_rule" "bastion_ingress" {
  type = "ingress"
  security_group_id = "${aws_security_group.bastion_sg.id}"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_egress" {
  type = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.web_app_sg.id}"
}


// Route tables
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "jldiamon-public_rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags = {
    Name = "jldiamon-private_rt"
  }
}


// Route table associations
resource "aws_route_table_association" "public-2a" {
  subnet_id      = "${aws_subnet.public-2a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public-2b" {
  subnet_id      = "${aws_subnet.public-2b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}


// SSH key/AWS key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo '${tls_private_key.ssh_key.private_key_pem}' > id_rsa && chmod 600 id_rsa"
    interpreter = ["bash", "-c"]
  }
}

resource "aws_key_pair" "app_key_pair" {
  key_name   = "jldiamon-key"
  public_key = "${tls_private_key.ssh_key.public_key_openssh}"
}


// Load balancer
resource "aws_lb" "lb" {
  name               = "jldiamon-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets = ["${aws_subnet.public-2a.id}", "${aws_subnet.public-2b.id}"]

  tags = {
    Name = "jldiamon-lb"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_tg.arn}"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "jldiamon-lb-tg"
  port     = 3000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    path = "/health_check"
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "lb_tga" {
  target_group_arn = "${aws_lb_target_group.lb_tg.arn}"
  target_id        = "${aws_instance.app.id}"
}


// EC2 instances
resource "aws_instance" "app" {
  ami           = "${var.ami_id}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.private.id}"
  security_groups = ["${aws_security_group.web_app_sg.id}", "${aws_security_group.basic_sg.id}"]
  key_name = "${aws_key_pair.app_key_pair.key_name}"

  provisioner "file" {
    source      = "app"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/app /opt/latest-build",
      "echo 'deb https://deb.nodesource.com/node_8.x xenial main' | sudo tee /etc/apt/sources.list.d/nodesource.list",
      "curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -",
      "sudo apt-get update && sudo apt-get install nodejs -y",
      "cd /opt/latest-build && npm install",
      "sudo cp /opt/latest-build/latest-build.service /lib/systemd/system && sudo chown root:root /lib/systemd/system/latest-build.service",
      "sudo systemctl start latest-build && sudo systemctl enable latest-build"
    ]
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("id_rsa")}"
    bastion_host = "${aws_eip.bastion_eip.public_ip}"
  }

  depends_on = ["aws_instance.bastion"]

  tags = {
    Name = "jldiamon-app"
  }
}

resource "aws_instance" "bastion" {
  ami           = "${var.ami_id}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.public-2a.id}"
  security_groups = ["${aws_security_group.bastion_sg.id}", "${aws_security_group.basic_sg.id}"]
  key_name = "${aws_key_pair.app_key_pair.key_name}"
  associate_public_ip_address = true

  tags = {
    Name = "jldiamon-bastion"
  }
}
