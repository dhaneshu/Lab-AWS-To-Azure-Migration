terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ----------------------
# Networking (VPC, Subnets, IGW, Route Tables)
# ----------------------

resource "aws_vpc" "simpleshop" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "simpleshop-vpc"
    App  = "simpleshop"
  }
}

resource "aws_internet_gateway" "simpleshop" {
  vpc_id = aws_vpc.simpleshop.id

  tags = {
    Name = "simpleshop-igw"
    App  = "simpleshop"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.simpleshop.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.aws_az

  tags = {
    Name = "simpleshop-public-subnet"
    App  = "simpleshop"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.simpleshop.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.aws_az_a

  tags = {
    Name = "simpleshop-private-subnet-a"
    App  = "simpleshop"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.simpleshop.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.aws_az_b

  tags = {
    Name = "simpleshop-private-subnet-b"
    App  = "simpleshop"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.simpleshop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.simpleshop.id
  }

  tags = {
    Name = "simpleshop-public-rt"
    App  = "simpleshop"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----------------------
# Security Groups
# ----------------------

resource "aws_security_group" "web" {
  name        = "simpleshop-web-sg"
  description = "Security group for SimpleShop web EC2 instance"
  vpc_id      = aws_vpc.simpleshop.id

  # Allow HTTP from anywhere (demo)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from configurable CIDR
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simpleshop-web-sg"
    App  = "simpleshop"
  }
}

resource "aws_security_group_rule" "web_ssh_from_azure_migrate" {
  count = var.deploy_azure_migrate_appliance ? 1 : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "SSH from Azure Migrate appliance"
  security_group_id        = aws_security_group.web.id
  source_security_group_id = aws_security_group.azure_migrate[0].id
}

resource "aws_security_group" "rds" {
  name        = "simpleshop-rds-sg"
  description = "Security group for SimpleShop RDS instance"
  vpc_id      = aws_vpc.simpleshop.id

  # DB access only from web SG
  ingress {
    description      = "DB access from web EC2"
    from_port        = var.db_port
    to_port          = var.db_port
    protocol         = "tcp"
    security_groups  = [aws_security_group.web.id]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    cidr_blocks      = []
    self             = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simpleshop-rds-sg"
    App  = "simpleshop"
  }
}

# ----------------------
# RDS (MySQL/PostgreSQL)
# ----------------------

resource "aws_db_subnet_group" "simpleshop" {
  name = "simpleshop-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = {
    Name = "simpleshop-db-subnet-group"
    App  = "simpleshop"
  }
}

resource "aws_db_instance" "simpleshop" {
  identifier        = "simpleshop-db"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.simpleshop.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible                 = false
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true

  deletion_protection = false

  tags = {
    Name = "simpleshop-db"
    App  = "simpleshop"
  }
}

# ----------------------
# IAM role for EC2 → RDS access
# ----------------------

locals {
  rds_db_user_arn = format(
    "arn:aws:rds-db:%s:%s:dbuser:%s/%s",
    var.aws_region,
    data.aws_caller_identity.current.account_id,
    aws_db_instance.simpleshop.resource_id,
    var.db_username,
  )
}

resource "aws_iam_role" "web" {
  name = "simpleshop-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "simpleshop-web-role"
    App  = "simpleshop"
  }
}

resource "aws_iam_role_policy" "web_rds_access" {
  name = "simpleshop-web-rds-access"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          local.rds_db_user_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBLogFiles",
          "rds:DescribeDBParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "simpleshop-web-instance-profile"
  role = aws_iam_role.web.name
}

# ----------------------
# EC2 Instance (SimpleShop Web App)
# ----------------------

resource "aws_instance" "web" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.web.name

  key_name = var.ec2_key_pair_name

  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.simpleshop.address
    db_port     = var.db_port
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  })

  tags = {
    Name = "simpleshop-web"
    App  = "simpleshop"
  }
}

output "web_public_ip" {
  description = "Public IP address of the SimpleShop web EC2 instance"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the SimpleShop RDS instance"
  value       = aws_db_instance.simpleshop.address
}
