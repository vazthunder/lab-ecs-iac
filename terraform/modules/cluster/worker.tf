resource "aws_security_group" "ecs-worker" {
  count = var.worker_ec2 ? 1 : 0
  
  name        = "${var.project}-${var.env}-ecs-worker"
  vpc_id      = var.vpc_id
  description = "${var.project}-${var.env}-ecs-worker"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ var.bastion-sg_id ]
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

resource "aws_iam_role" "ecs-worker" {
  count = var.worker_ec2 ? 1 : 0

  name = "${var.project}-${var.env}-ecs-worker-role"
  
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
}

resource "aws_iam_role_policy_attachment" "ecs-worker-ec2" {
  count = var.worker_ec2 ? 1 : 0

  role       = aws_iam_role.ecs-worker[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-worker" {
  count = var.worker_ec2 ? 1 : 0

  name = "${var.project}-${var.env}-ecs-worker"
  role = aws_iam_role.ecs-worker[0].id
}

resource "aws_launch_template" "ecs-worker" {
  count = var.worker_ec2 ? 1 : 0

  name                   = "${var.project}-${var.env}-ecs-worker"
  image_id               = data.aws_ami.aws_optimized_ecs.id
  instance_type          = var.worker_instance_type
  key_name               = var.key_name
  user_data              = base64encode(templatefile("${path.module}/user_data.sh", { 
                            cluster_name = "${var.project}-${var.env}-cluster" }))
  vpc_security_group_ids = [ aws_security_group.ecs-worker[0].id ]
  ebs_optimized          = true
  
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs-worker[0].arn
  }

  credit_specification {
    cpu_credits = "standard"
  }

  block_device_mappings {
    device_name             = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.worker_storage_size
      delete_on_termination = true
    }
  }
}

resource "aws_autoscaling_group" "ecs-worker" {
  count = var.worker_ec2 ? 1 : 0

  name                      = "${var.project}-${var.env}-ecs-worker"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = [ var.subnet-private-a_id, var.subnet-private-b_id ]
  min_size                  = 0
  max_size                  = var.worker_max_size
  desired_capacity          = 0     # Managed by ECS
  protect_from_scale_in     = true  # Managed by ECS

  launch_template {
    id      = aws_launch_template.ecs-worker[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.env}-ecs-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Group"
    value               = "${var.project}-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [ desired_capacity ]
  }
}
