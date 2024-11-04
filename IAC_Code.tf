
Providers and Variables (providers.tf, variables.tf)

provider "aws" {
  region = "us-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

VPC Module (vpc/main.tf)

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "myapp-vpc"
  cidr   = "10.0.0.0/16"
  azs    = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
}

Web Tier (web/main.tf)

resource "aws_launch_configuration" "web_config" {
  name          = "web-config"
  image_id      = "ami-12345678"
  instance_type = var.instance_type
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_config.id
  vpc_zone_identifier  = module.vpc.public_subnets
  min_size             = 1
  max_size             = 3
  tags = [
    {
      key                 = "Name"
      value               = "web-server"
      propagate_at_launch = true
    }
  ]
}

resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
}

Database Tier (database/main.tf)

resource "aws_db_instance" "db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydatabase"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  multi_az             = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
