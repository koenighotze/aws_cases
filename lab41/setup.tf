variable "ami_id" {
  default = "ami-1c45e273"
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
  profile = "${var.profile_name}"
}

resource "aws_iam_role" "s3-bucket-access" {
  name = "lab41-aws-s3-bucket-access"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": ["s3:ListAllMyBuckets", "s3:GetObject", "s3:ListBucket"]
        }
      ]
    }
EOF
}

resource "aws_s3_bucket" "bucket" {
  bucket = "lab41-dschmitz-bucket"

  tags {
    Owner = "${var.owner}"
    Costcenter = "${var.cost_center}"
    Name = "lab41"
  }
}

#
#  attach role to instance
#  Install aws cli on instance? Not needed??!?!
#  No credential setup needed
#  aws s3 list

resource "aws_security_group" "sec-group" {
  name = "lab41-security-group"

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

resource "aws_iam_instance_profile" "s3-access-profile" {
  name = "lab41-access-profile"
  role = "${aws_iam_role.s3-bucket-access.name}"
}

resource "aws_instance" "lab41" {
  ami           = "${data.aws_ami.web.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.s3-access-profile.id}"

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/us-west-2.ec2.archive/eu-central-1.ec2.archive/g' /etc/apt/sources.list",
      "sudo apt-get update"
    ]

    connection {
      timeout = "10m"
      user = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }

  tags {
    Name = "lab41"
    CostCenter = "${var.cost_center}"
    Owner = "${var.owner}"
  }
}

output "ip" {
  value  = "${aws_instance.lab41.public_ip}"
}

output "role-arn" {
  value  = "${aws_iam_role.s3-bucket-access.arn}"
}

output "bucket_domain_name" {
  value = "${aws_s3_bucket.bucket.bucket_domain_name}"

}