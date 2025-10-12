terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.16.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

#vpc
resource "aws_vpc" "jenkins-ec2-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "jenkins-ec2-vpc"
  }
}

#subnet
resource "aws_subnet" "jenkins-ec2-subnet" {
  vpc_id     = aws_vpc.jenkins-ec2-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "jenkins-ec2-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "jenkins-ec2-igw" {
  vpc_id = aws_vpc.jenkins-ec2-vpc.id
  tags = {
    Name = "jenkins-ec2-igw"
  }
}

# Route Table
resource "aws_route_table" "jenkins-ec2-rtb" {
  vpc_id = aws_vpc.jenkins-ec2-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-ec2-igw.id
  }

  tags = {
    Name = "jenkins-ec2-rtb"
  }
}

# Route Table Association
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.jenkins-ec2-subnet.id
  route_table_id = aws_route_table.jenkins-ec2-rtb.id
}

#security groups

resource "aws_security_group" "jenkins-ec2-sg" {
  name        = "jenkins-ec2-sg"
  description = "Allow ssh & jenkins and all outbound traffic"
  vpc_id      = aws_vpc.jenkins-ec2-vpc.id

    ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-ec2-sg"
  }
}

#iam role
resource "aws_iam_role" "jenkins-ec2-role" {
  name = "jenkins-ec2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#iam policy
resource "aws_iam_role_policy_attachment" "jenkins-ec2-policy" {
  role       = aws_iam_role.jenkins-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

#iam instance profile
resource "aws_iam_instance_profile" "jenkins-ec2-profile" { 
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins-ec2-role.name
}

#ami
data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#EC2 Instance with jenkins
resource "aws_instance" "jenkins-ec2-vm" {
   ami = data.aws_ssm_parameter.amazon_linux_2.value
   instance_type = "t2.micro"
   subnet_id = aws_subnet.jenkins-ec2-subnet.id
   vpc_security_group_ids = [aws_security_group.jenkins-ec2-sg.id]
   iam_instance_profile = aws_iam_instance_profile.jenkins-ec2-profile.name
   associate_public_ip_address = true

   tags = {
    Name = "jenkins-ec2-vm"
   }

   user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-17-amazon-corretto
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF
}
