
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# S3 create bucket
resource "aws_s3_bucket" "test_bucket" {
  bucket = "${var.bucket}"
  acl    = "private"
  region = "${var.region}"
  tags = {
    Name = "${var.bucket}"
  }
}

# S3 upload index.html to bucket
resource "aws_s3_bucket_object" "object" {
  bucket     = "${var.bucket}"
  key        = "index.html"
  source     = "static_page/index.html"
  depends_on = ["aws_s3_bucket.test_bucket"]
}

# S3 bucket read role
resource "aws_iam_role" "s3-read_role" {
  name               = "S3read_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
# S3 bucket read profile
resource "aws_iam_instance_profile" "s3-read_profile" {
  name = "S3read_profile"
  role = "${aws_iam_role.s3-read_role.name}"
}

# S3 bucket read policy
resource "aws_iam_role_policy" "s3read_policy" {
  name = "S3read_policy"
  role = "${aws_iam_role.s3-read_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
               "s3:List*"
            ],
            "Resource": "arn:aws:s3:::${var.bucket}/*"
        }
            ]
}
EOF
}

# ALB self-signed cert
resource "aws_iam_server_certificate" "self_signed" {
  name             = "self_signed"
  certificate_body = "${file("${var.certificate_body}")}"
  private_key      = "${file("${var.private_key}")}"
}


# Creating security group
resource "aws_security_group" "traffic-in-win" {
  name        = "traffic-in-win"
  description = "Allow inbound web traffic"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Allow_Web"
  }
}

# Creating EC2 instance 1
resource "aws_instance" "my_Windows1" {
  ami                  = "ami-0378c96af0ed74c0b"
  instance_type        = "t2.micro"
  security_groups      = ["traffic-in-win"]
  key_name             = "${var.ec2_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.s3-read_profile.name}"
  depends_on           = ["aws_s3_bucket.test_bucket", "aws_s3_bucket_object.object", "aws_security_group.traffic-in-win", "aws_iam_instance_profile.s3-read_profile"]
  user_data            = <<EOF
<powershell>
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName "Port" -Value "8080"
New-NetFirewallRule -DisplayName "Open_IIS_PORT_IN" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080
New-NetFirewallRule -DisplayName "Open_IIS_PORT_OUT" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8080

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name AWSPowerShell -Force
Remove-Item -path c:\inetpub\wwwroot\* -Filter *iisstart*
Read-S3Object -BucketName "${var.bucket}" -Key "index.html" -File "c:\inetpub\wwwroot\index.html"
</powershell>
EOF
tags = {
  Name = "Windows-Server1"
}
}

# Creating EC2 instance 2
resource "aws_instance" "my_Windows2" {
  ami = "ami-0378c96af0ed74c0b"
  instance_type = "t2.micro"
  security_groups = ["traffic-in-win"]
  key_name = "mytestwinda"
  iam_instance_profile = "${aws_iam_instance_profile.s3-read_profile.name}"
  depends_on = ["aws_s3_bucket.test_bucket", "aws_s3_bucket_object.object", "aws_security_group.traffic-in-win", "aws_iam_instance_profile.s3-read_profile"]
  user_data = <<EOF
<powershell>
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName "Port" -Value "8080"
New-NetFirewallRule -DisplayName "Open_IIS_PORT_IN" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080
New-NetFirewallRule -DisplayName "Open_IIS_PORT_OUT" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8080

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name AWSPowerShell -Force
Remove-Item -path c:\inetpub\wwwroot\* -Filter *iisstart*
Read-S3Object -BucketName "${var.bucket}" -Key "index.html" -File "c:\inetpub\wwwroot\index.html"
</powershell>
EOF
  tags = {
    Name = "Windows-Server2"
  }
}

# Creating Application Load Balancer
resource "aws_alb" "alb_front" {
  name            = "alb-front"
  internal        = false
  security_groups = ["${aws_security_group.traffic-in-win.id}"]
  subnets         = ["${var.subnets[0]}", "${var.subnets[1]}", "${var.subnets[2]}"]
  tags = {
    Environment = "testing"
  }
}

# Creating ALB target group
resource "aws_alb_target_group" "alb_front_http" {
  name     = "alb-front-https"
  vpc_id   = "${var.vpc_id}"
  port     = "8080"
  protocol = "HTTP"
  health_check {
    path                = "/index.html"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 4
  }
}

# Creating ALB target group attachment 1
resource "aws_alb_target_group_attachment" "alb_backend-01_http" {
  target_group_arn = "${aws_alb_target_group.alb_front_http.arn}"
  target_id        = "${aws_instance.my_Windows1.id}"
  port             = 8080
  depends_on       = ["aws_instance.my_Windows1"]
}
# Creating ALB target group attachment 2
resource "aws_alb_target_group_attachment" "alb_backend-02_http" {
  target_group_arn = "${aws_alb_target_group.alb_front_http.arn}"
  target_id        = "${aws_instance.my_Windows2.id}"
  port             = 8080
  depends_on       = ["aws_instance.my_Windows2"]
}

# Creating ALB https listener
resource "aws_alb_listener" "alb_front_http" {
  load_balancer_arn = "${aws_alb.alb_front.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_iam_server_certificate.self_signed.arn}"
  default_action {
    target_group_arn = "${aws_alb_target_group.alb_front_http.arn}"
    type             = "forward"
  }
}

