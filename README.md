# Nagdom

Variables needed for the Terraform configuration
terraform.tf
```
// credentials
access_key = ""
secret_key = ""

// define instance-specific settings
region = "us-west-2"
instance_size = "t2.large"
ec2_role_name = ""
hostname = "nagdom"
fqdn = "nagdom.domain.com"

//reference data
amis = { 
    //amzn-ami-hvm-2017.03.0.20170401-x86_64-gp2
    "us-east-1" = "ami-22ce4934"
    "us-east-2" = "ami-7bfcd81e"
    "us-west-2" = "ami-8ca83fec"
}

key_name = "key-pair-name"
ssh_key = "/path/to/key.pem"

hosted_zone_id = "" //route53 hosted zone id
vpc_cidr = "10.0.0.0/24"
inbound_safelist = [
    "10.0.0.0/24"
]
```