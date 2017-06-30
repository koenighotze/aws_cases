variable "ami_id" {
  default = "ami-1c45e273"
}

variable "owner" {
  default = "dschmitz"
}

variable "cost_center" {
  default = "tecco"
}

variable "key_name" {
  default = "dschmitz_senacor_aws"
}

variable "key_path" {
  default = "/Users/dschmitz/.ssh/aws/dschmitz_senacor_aws.pem"
}

####

data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name = "name"
    values = ["t2.micro"]
  }

  most_recent = true
}

provider "aws" {
  region = "eu-central-1"
  profile = "tecco"
}

resource "aws_security_group" "sec-group" {
  name = "lab29-security-group"

  # allow incomming ssh
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow incomming http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow incomming https
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Owner = "${var.owner}"
    Costcenter = "${var.cost_center}"
  }
}

resource "aws_instance" "lab29" {
  ami           = "${data.aws_ami.web.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/us-west-2.ec2.archive/eu-central-1.ec2.archive/g' /etc/apt/sources.list",
      "sudo apt-get update",
      "sudo apt-get install -y apache2",
      "sudo chown ubuntu:ubuntu /var/www/html/",
      "sudo /bin/rm /var/www/html/index.html",
    ]

    connection {
      timeout = "10m"
      user = "ubuntu"
      private_key = "${file("/Users/dschmitz/.ssh/aws/dschmitz_senacor_aws.pem")}"
    }
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/var/www/html/index.html"

    connection {
      timeout = "1m"
      user = "ubuntu"
      private_key = "${file("/Users/dschmitz/.ssh/aws/dschmitz_senacor_aws.pem")}"
    }
  }

  tags {
    Name = "lab29"
    CostCenter = "${var.cost_center}"
    Owner = "${var.owner}"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.lab29.id}"
}

output "ip" {
  value  = "${aws_eip.ip.public_ip}"
}