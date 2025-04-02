resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub_1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub_2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }
  
}

resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.sub_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id = aws_subnet.sub_2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "websg" {
  name        = "websg"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

  tags = {
    Name = "websg"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "terraformprojectsuneetha2025"
}

resource "aws_instance" "webserver1" {
  ami = "ami-0e35ddab05955cf57"
  instance_type = "t2.micro" 
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub_1.id
}

resource "aws_instance" "webserver2" {
  ami = "ami-0e35ddab05955cf57"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub_2.id  
}

resource "aws_lb" "alb" {
  name = "myalb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.websg.id]
  subnets = [aws_subnet.sub_1.id , aws_subnet.sub_2.id]

  tags = {
    Name = "web"
  }
}

  resource "aws_lb_target_group" "tg" {
    name = "myTG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id 

    health_check {
      path = "/"
      port = "traffic-port"
    }
  }

  resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.webserver1.id
    port = 80
  }

    resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.webserver2.id
    port = 80
  }

  resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"     
  
  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type = "forward"
  }

  }

  output "loadbalancerdns" {
    value = aws_lb.alb.dns_name

  }