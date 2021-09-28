terraform{
  required_providers {
    aws={
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}


resource "aws_launch_configuration" "tflaunchconfig" {
  name          = "tflaunchconfig"
  image_id      = "${lookup(var.amis, var.region_var)}"
  instance_type = "t2.small"
  key_name = "${aws_key_pair.terraform-key.key_name}"
  associate_public_ip_address = true
  user_data = <<USER_DATA
  #!bin/bash
  apt-get update
  apt-get install -y tree
  apt-get install -y apache2
  systemctl start apache2.service
  echo "this is on tomcat server" >> /var/www/html/index.html
  USER_DATA
  lifecycle {
    create_before_destroy  = true
  }
}

resource "aws_key_pair" "terraform-key" {
  key_name   = "newterraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCI9jGEv6E8Yk5CPiURFFMqFAe53cdNhm12crkar70VOf8+rm75eD01R4aT+wxpvw0ER0PJILvP/rAjcahHmOv7D5LGDpJqOR11hCvenZ0eEhE2CE8JUEA2DOIkDuXozKnOZkB9yqDePN0OM3bsybG9omeATwAfdVJbKHcdpp8me963c4uQjF8kcUBc05uVFCBBaukE3TuNY4pviPqnpT1FXnbpbpYIgSrCTtC6ZlpiQh3VfLeN4XSPkV1qp/7AgHorFi8VDgzPZyf8rI/crNA6H6STZkBJiz3k6ljD93IscNkwUasvG+z0IVGaIAUIM/pNBRo6TqYgyT5NsDGFEiif"
}

resource "aws_elb" "myelb" {
  name ="loadbalancer"
  security_groups = [ "${aws_security_group.elb_securitygrp1.id}" ]
  subnets = [ 
    "${aws_subnet.subnet_01.id}",
    "${aws_subnet.subnet_02.id}"
    ]
    cross_zone_load_balancing = true
    health_check {
      healthy_threshold  =2
      unhealthy_threshold = 2
      timeout = 3
      interval = 30
      target = "HTTP:80/"
    }
    listener {
      lb_port = 80
      lb_protocol = "http"
      instance_port = "80"
      instance_protocol = "http"
    }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "tflaunchconfig-asg"
  min_size =  1
  desired_capacity = 2
  max_size = 4
  health_check_type = "ELB"
  load_balancers = [ "${aws_elb.myelb.id}" ]
  launch_configuration = "${aws_launch_configuration.tflaunchconfig.name}"
  enabled_metrics = [ "GroupMinSize",
                      "GroupMaxSize",
                      "GroupDesiredCapacity",
                      "GroupInServiceInstances",
                      "GroupTotalInstances" 
                      ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier = [ "${aws_subnet.subnet_01.id}",
    "${aws_subnet.subnet_02.id}" ]

    lifecycle {
      create_before_destroy = true
    }
    tag {
      key ="Name"
      value="web"
      propagate_at_launch = true
    }
}

resource "aws_autoscaling_policy" "policyup" {
  name="webpolicyup"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web_asg.name}"
}


resource "aws_autoscaling_policy" "policydown" {
  name="webpolicydown"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web_asg.name}"
}


resource "aws_cloudwatch_metric_alarm" "webalarmup" {
  alarm_name = "myalarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = "60"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web_asg.name}"
  }
  alarm_description = "monitors the cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.policyup.arn}"]
}


resource "aws_cloudwatch_metric_alarm" "webalarmdown" {
  alarm_name = "myalarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = "10"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web_asg.name}"
  }
  alarm_description = "monitors the cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.policydown.arn}"]
}
resource "aws_vpc" "mainvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "mainvpc"
  }
}

resource "aws_subnet" "subnet_01"{
  vpc_id = "${aws_vpc.mainvpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name ="subnet for south 1a"
  }
}

resource "aws_subnet" "subnet_02"{
  vpc_id = "${aws_vpc.mainvpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name ="subnet for south 1b"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = "${aws_vpc.mainvpc.id}"
  tags = {
    "Name" = "My internetgateway"
  }
}

# resource "aws_route_table" "myroutetable" {
#   vpc_id = "${aws_vpc.mainvpc.id}"
#   route =  [{ 
#     cidr_block = "0.0.0.0/0"
#     gateway_id = "${aws_internet_gateway.myigw.id}"
    
#   } ]
#   tags={
#     Name ="my routeTable"
#   }
# }

# resource "aws_route_table_association" "myroutetableassociation01" {
#   subnet_id = "${aws_subnet.subnet_01.id}"
#   route_table_id = "${aws_route_table.myroutetable.id}"
# }

# resource "aws_route_table_association" "myroutetableassociation02" {
#   subnet_id = "${aws_subnet.subnet_02.id}"
#   route_table_id = "${aws_route_table.myroutetable.id}"
# }

resource "aws_security_group" "mysecuritygrp" {
  name = "allow_http"
  description = "allow http inbound connections"
  vpc_id = "${aws_vpc.mainvpc.id}"
  ingress {
    description= "allow tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  } 
  ingress {
    description= "allow ssh"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  } 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_securitygrp1" {
  name = "elb_allow_http"
  description = "allow http inbound connections"
  vpc_id = "${aws_vpc.mainvpc.id}"
  ingress {
    description= "allow tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  } 
  ingress {
    description= "allow ssh"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  } 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Region
# resource "aws_iam_role" "terraforms3role08062021" {
#   name = "terraforms3role08062021"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   tags = {
#     tag-key = "terraform-role"
#   }
# }

# resource "aws_iam_role_policy" "test_policy" {
#   name = "test_policy"
#   role = aws_iam_role.terraforms3role08062021.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "s3:*"
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

# resource "aws_iam_instance_profile" "terra_profile" {
#   name = "terra_profile"
#   role = "${aws_iam_role.terraforms3role08062021.name}"
# }


#  resource "aws_instance" "role-Terraform" {
#   ami = "ami-010aff33ed5991201"
#   instance_type = var.intancetype_var
#   iam_instance_profile = "${aws_iam_instance_profile.terra_profile.name}"
#   key_name = "terraform_key"
#   tags = {
#     Name = "terra-instancess"
#   }
#   connection {
#     type="ssh"
#     user="ec2-user"
#     private-key="${file(var.filename)}"
#     host = aws_instance.web.public_ip
#   }
#   }

#End Region