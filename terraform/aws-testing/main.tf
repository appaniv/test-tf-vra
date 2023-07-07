terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
 
}





# Create a security group for the Ubuntu instance
resource "aws_security_group" "ubuntu_instance_sg" {
  name        = "ubuntu_instance_sg"
  description = "Security group for Ubuntu instance"
  vpc_id = "vpc-55229428"

  # Allow SSH access to the test Ubuntu instance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ubuntu instance with AMI ami-053b0d53c279acc90
resource "aws_instance" "ubuntu_instance" {
  ami           = "ami-053b0d53c279acc90" 
  instance_type = "t2.micro"
  key_name      = "vj-key-pair"
  subnet_id     = "subnet-3b3b0e76" #subnet from console for vpc vpc-55229428 us-east-1c
  vpc_security_group_ids = [aws_security_group.ubuntu_instance_sg.id]

  # Use user data to install OpenSSH server on the instance
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y openssh-server
  
  EOF
}

# Output the public IP of the Ubuntu instance
output "public_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}





## RDS Cluster with 2 instance 
resource "aws_rds_cluster" "terraform-rds-cluster" {
  cluster_identifier = "rds-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "13.6"
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password
	skip_final_snapshot = "true"

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "rds_instance" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.terraform-rds-cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.terraform-rds-cluster.engine
  engine_version     = aws_rds_cluster.terraform-rds-cluster.engine_version
}



output "public_ip" {
 value = aws_instance.ubuntu_instance.public_ip
}



