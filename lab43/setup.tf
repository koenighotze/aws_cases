variable "ami_id" {
  default = "ami-82be18ed" # use amazon ami, due to bug in cloudinit :(
}

variable "owner" {
  default = "dschmitz"
}

variable "cost_center" {
  default = "tecco"
}

variable "profile_name" {
  default = "tecco"
}

variable "key_name" {
  default = "dschmitz_senacor_aws"
}

variable "key_path" {
  default = "/Users/dschmitz/.ssh/aws/dschmitz_senacor_aws.pem"
}

####

# data "aws_ami" "web" {
#   filter {
#     name   = "state"
#     values = ["available"]
#   }

#   filter {
#     name = "name"
#     values = ["t2.micro"]
#   }

#   most_recent = true
# }

provider "aws" {
  region = "eu-central-1"
  profile = "${var.profile_name}"
}

resource "aws_security_group" "sec-group" {
  name = "lab43-security-group"

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

resource "aws_instance" "lab43" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  user_data = "${file("setup.sh")}"

  tags {
    Name = "lab43"
    CostCenter = "${var.cost_center}"
    Owner = "${var.owner}"
  }
}

output "ip" {
  value  = "${aws_instance.lab43.public_ip}"
}