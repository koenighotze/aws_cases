variable "ami_id" {
  default = "ami-1c45e273"
}

variable "name" {
  default = "lab33"
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

variable "snapshot_id" {}

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
  name = "${var.name}-security-group"

  # allow incomming ssh
  ingress {
    from_port = 22
    to_port = 22
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

resource "aws_ebs_volume" "extradata" {
  availability_zone = "eu-central-1b"
  size = 8
  tags {
      Name = "${var.name}"
  }
}

resource "aws_ebs_volume" "snapshot" {
  availability_zone = "eu-central-1b"
  snapshot_id = "${var.snapshot_id}"
  tags {
      Name = "${var.name}-snapshot"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.extradata.id}"
  instance_id = "${aws_instance.lab.id}"
}

resource "aws_volume_attachment" "ebs_att_snapshot" {
  device_name = "/dev/sdi"
  volume_id   = "${aws_ebs_volume.snapshot.id}"
  instance_id = "${aws_instance.lab.id}"
}

resource "aws_instance" "lab" {
  ami           = "${data.aws_ami.web.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  tags {
    Name = "${var.name}"
    CostCenter = "${var.cost_center}"
    Owner = "${var.owner}"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.lab.id}"
}

output "ip" {
  value  = "${aws_eip.ip.public_ip}"
}