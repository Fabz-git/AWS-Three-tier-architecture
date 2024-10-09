

resource "aws_vpc" "three_tier_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "three-tier-vpc"
  }
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.public_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-1"
  }
}


resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.public_subnet_2_cidr
  map_public_ip_on_launch = true
availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet-2"
  }
}


resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}


resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}


resource "aws_subnet" "private_subnet_3" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_3_cidr
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-3"
  }
}

  resource "aws_subnet" "private_subnet_4" {
  vpc_id     = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_4_cidr
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-4"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three_tier_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc" 
}


resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "three_tier_web_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "three_tier_web_rt"
  }
}


resource "aws_route_table" "three_tier_app_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "three_tier_app_rt"
  }
}


resource "aws_route_table_association" "three_tier_rt_as_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.three_tier_web_rt.id
}

resource "aws_route_table_association" "three_tier_rt_as_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.three_tier_web_rt.id
}

resource "aws_route_table_association" "three_tier_rt_as_3" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.three_tier_app_rt.id
}

resource "aws_route_table_association" "three_tier_rt_as_4" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.three_tier_app_rt.id
}

resource "aws_route_table_association" "three_tier_rt_as_5" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.three_tier_app_rt.id
}

resource "aws_route_table_association" "three_tier_rt_as_6" {
  subnet_id      = aws_subnet.private_subnet_4.id
  route_table_id = aws_route_table.three_tier_app_rt.id
}


resource "aws_autoscaling_group" "three_tier_web_asg" {
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  launch_template {
    id      = aws_launch_template.three_tier_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "three-tier-instance"
    propagate_at_launch = true
  }
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
}


resource "aws_launch_template" "three_tier_launch_template" {
  name_prefix   = "three_tier_template"
  image_id      = var.image_id        # AMI ID to use for the instances
  instance_type = var.instance_type    # Instance type to use

                 # Specify the key pair name for SSH access

  network_interfaces {
    associate_public_ip_address = true  # Enable if the tier needs public IP
    subnet_id                   = aws_subnet.public_subnet_1.id  # Specify the subnet ID
    security_groups             = [aws_security_group.three_tier_asg_sg.id]  # Security group for the instances
  }

  user_data = <<-EOF
              #!/bin/bash
              # Simple user data script to install Apache
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Three Tier Architecture!</h1>" | sudo tee /var/www/html/index.html
              EOF

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }

  tags = {
    Name = "Three-Tier Instance"
  }
}



resource "aws_security_group" "three_tier_asg_sg" {
  vpc_id      = aws_vpc.three_tier_vpc.id
  name        = "security-group"
  description = "Allow SSH and http and https"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["10.0.2.0/24"]
  }
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

}



resource "aws_lb" "three_tier_web_lb" {
  name               = "three-tier-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.three_tier_asg_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]


  tags = {
    Environment = "three_tier_web_lb"
  }
}


resource "aws_lb_target_group" "three_tier_web_lb_tg" {
  name     = "three-tier-web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier_vpc.id

health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}



resource "aws_lb_listener" "HTTP_listener" {
  load_balancer_arn = aws_lb.three_tier_web_lb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.three_tier_web_lb_tg.arn
  }
}


resource "aws_autoscaling_attachment" "three_tier_web_autoscaling_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.three_tier_web_asg.id
  lb_target_group_arn    = aws_lb_target_group.three_tier_web_lb_tg.arn
}