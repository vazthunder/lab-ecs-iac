resource "aws_security_group" "bastion" {
  name          = "${var.project}-${var.env}-bastion"
  vpc_id        = var.vpc_id
  description   = "${var.project}-${var.env}-bastion"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_iam_role" "bastion" {
  name = "${var.project}-${var.env}-bastion"
  
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [{
      Action: "sts:AssumeRole"
      Principal: {
        Service: "ec2.amazonaws.com"
      }
      Effect: "Allow"
    }]
  })

  inline_policy {
    name = "bastion-ecr"

    policy = jsonencode({
      Version: "2012-10-17"
      Statement: [{
        Action: "ecr:*"
        Resource: "*"
        Effect: "Allow"
      }]
    })
  }
}

resource "aws_iam_role_policy_attachment" "bastion-ecs" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-${var.env}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  ami                     = var.bastion_ami_id
  instance_type           = var.bastion_instance_type
  key_name                = var.key_name
  subnet_id               = var.subnet-public-a_id
  vpc_security_group_ids  = [ aws_security_group.bastion.id ]
  iam_instance_profile    = aws_iam_instance_profile.bastion.name
  user_data_base64        = filebase64("${path.module}/userdata.sh")
  ebs_optimized           = true

  credit_specification {
    cpu_credits           = "standard"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_storage_size
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.project}-${var.env}-bastion"
    Group = "${var.project}-${var.env}"
  }
}
