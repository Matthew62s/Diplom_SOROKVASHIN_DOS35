provider "aws" {
        access_key = var.AWS_access
        secret_key = var.AWS_secret
        region     = var.region
}

resource "aws_vpc" "main" {
 cidr_block = "172.31.0.0/16"
 
 tags = {
   Name = "CI/CD VPC"
 }
}

resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 map_public_ip_on_launch = true
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "CI/CD Internet Gateway"
 }
}

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table CI/CD"
 }
}

resource "aws_security_group" "server_sg" {
  name        = "server-sg"
  description = "Main security group for Kubernetes server"
  vpc_id      = aws_vpc.main.id

   # Allow SSH access
  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ping внутри VPC
  ingress {
    description = "Allow ICMP inside VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # etcd
  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # kubelet
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # kube-controller-manager
  ingress {
    description = "Kube Controller Manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # kube-scheduler
  ingress {
    description = "Kube Scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Kubernetes Server SG"
  }
}

resource "aws_key_pair" "ci-cd" {
  key_name   = "cicd-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFpdRe0UDhi97w2BKtP8Vvu1TSNOJ6erv9UQ9m6a/BJt cicd-key"
}

resource "aws_instance" "Master_node" {
	count         = 1
	ami           = "ami-0da1f66573556d917"
	instance_type = var.instance_type
	key_name = aws_key_pair.ci-cd.key_name
	tags = { 
		Name = "AWS_Master_server"
		Owner = "Matt"
		Project = "CI/CD"
	}
	subnet_id = aws_subnet.public_subnets[0].id
	associate_public_ip_address = true
	vpc_security_group_ids = [
    	aws_security_group.server_sg.id
  	]
}

resource "aws_instance" "Worker_node" {
	count         = 1
	ami           = "ami-0da1f66573556d917"
	instance_type = var.instance_type
	key_name = aws_key_pair.ci-cd.key_name
	tags = { 
		Name = "AWS_Worker_server_1"
		Owner = "Matt"
		Project = "CI/CD"
	}
	subnet_id = aws_subnet.public_subnets[0].id
	associate_public_ip_address = true
	vpc_security_group_ids = [
    	aws_security_group.server_sg.id
  	]
}
backend "s3" {
    region = var.region
    bucket = "terraform-669707689097-eu-north-1-an"
    key  = "states/terraform.tfstate"
}
