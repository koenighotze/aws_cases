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

provider "aws" {
  region = "eu-central-1"
  profile = "${var.profile_name}"
}

# prepare bucket with webpage
resource "aws_s3_bucket" "bucket" {
  bucket = "lab43-bucket"
  acl = "private"

  tags {
    Owner = "${var.owner}"
    Costcenter = "${var.cost_center}"
    Name = "lab43"
  }
}

resource "aws_s3_bucket_object" "index-file" {
  bucket = "${aws_s3_bucket.bucket.bucket}"
  key    = "index.html"
  source = "index.html"
}

# create role and policy for s3 access
resource "aws_iam_role" "lab43-aws-s3-bucket-access-role" {
  name = "lab43-aws-s3-bucket-access-role"

  # who may use this role. In this case EC2 instances
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3-bucket-access-policy" {
  name = "lab43-aws-s3-bucket-access-policy"
  role = "${aws_iam_role.lab43-aws-s3-bucket-access-role.id}"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
]
}
EOF
}

resource "aws_iam_instance_profile" "s3-access-profile" {
  name = "lab43-access-profile"
  role = "${aws_iam_role.lab43-aws-s3-bucket-access-role.name}"
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
  iam_instance_profile = "${aws_iam_instance_profile.s3-access-profile.id}"

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