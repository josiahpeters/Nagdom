//////////////////////////////
//  VARS
//////////////////////////////

// to be defined /////////////
// use tfvars file(s) or set inline

variable "access_key" {}
variable "secret_key" {}
variable "key_name" {}
variable "ssh_key" {}
variable "ec2_role_name" {}
variable "hosted_zone_id" {}
variable "hostname" {}
variable "fqdn" {}
variable "inbound_safelist" { type = "list" }

// defaults //////////////////
variable vpc_cidr {
 default = "10.0.0.0/24"
}
variable subnet_a_cidr {
  default = "10.0.0.0/28"
}
variable subnet_b_cidr {
  default = "10.0.0.16/28"
}
variable subnet_c_cidr {
  default = "10.0.0.32/28"
}
variable "region" {
  default = "us-west-2"
}
variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-22ce4934"
    "us-east-2" = "ami-7bfcd81e"
    "us-west-2" = "ami-8ca83fec"
  }
}
variable "instance_size" {
  default = "t2.large"
}
# variable "security_group" {
#   default = "sg-0b4e3b73"
# }
# variable "subnet_id" {
#   default = "subnet-2cf98c5b"
# }

//////////////////////////////
//  PROVIDER
//////////////////////////////

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

//////////////////////////////
//  RESOURCES
//////////////////////////////

resource "aws_vpc" "nagdom_vpc" {
  cidr_block = "${var.vpc_cidr}"
  
  tags {
    Name = "${var.hostname}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.nagdom_vpc.id}"
}

resource "aws_route" "r" {
  route_table_id = "${aws_vpc.nagdom_vpc.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_security_group" "sg_allow_all" {
  name        = "allow_all"
  description = "Allow all inbound/outbound traffic within VPC"
  depends_on = [ "aws_vpc.nagdom_vpc" ]
  vpc_id = "${aws_vpc.nagdom_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.inbound_safelist}"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id = "${aws_vpc.nagdom_vpc.id}"
  cidr_block = "${var.subnet_a_cidr}"
  availability_zone = "${var.region}a"
  depends_on = [ "aws_vpc.nagdom_vpc" ]

  tags {
    Name = "${var.hostname}-subnet_a"
  }
}

resource "aws_instance" "nagdom_host" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_size}"
  iam_instance_profile = "${var.ec2_role_name}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.sg_allow_all.id}"]
  subnet_id = "${aws_subnet.subnet_a.id}"

  tags {
    Name = "${var.fqdn}"
    provisioner = "terraform"
  }
}

resource "aws_eip" "nagdom_host-ip" {

}

resource "aws_route53_record" "domain_record" {
  zone_id = "${var.hosted_zone_id}"
  name = "${var.hostname}"
  type = "A"
  ttl = "300"
  records = [ "${aws_eip.nagdom_host-ip.public_ip}" ]
  depends_on = [ "aws_eip.nagdom_host-ip" ]
}

resource "aws_eip_association" "nagdom_host-ip-assoc" {
  instance_id = "${aws_instance.nagdom_host.id}"
  allocation_id = "${aws_eip.nagdom_host-ip.id}"
  depends_on = ["aws_instance.nagdom_host", "aws_route53_record.domain_record", "aws_internet_gateway.gw"]

  provisioner "remote-exec" {
    # script = "bootstrap.sh"
    inline = [
      "sleep 60",
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo curl -L 'https://github.com/docker/compose/releases/download/1.12.0/docker-compose-Linux-x86_64' | sudo tee /usr/local/bin/docker-compose > /dev/null",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo yum install git-all -y",
      #"echo 'alias ls=\\\'ls -lah --color\\\''>> ~/.bashrc",
      #"echo 'alias l=\\\'ls\\\'' >> ~/.bashrc",
      "cd ~",
      "git clone --depth 1 --branch dev https://github.com/josiahpeters/Nagdom.git",
      "cd Nagdom",
      "sudo chmod +x start-nagdom.sh",
      "./start-nagdom.sh"
    ]

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file(var.ssh_key)}"
      host = "${var.fqdn}"
    }
  }
}
