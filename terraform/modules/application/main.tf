resource "aws_security_group" "ecs-application" {
  name        = "${var.project}-${var.env}-${var.app_name}"
  vpc_id      = var.vpc_id
  description = "${var.project}-${var.env}-${var.app_name}"

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [ var.alb-sg_id ]
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

resource "aws_iam_role" "ecs-application" {
  name = "${var.project}-${var.env}-${var.app_name}-role"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Action: "sts:AssumeRole"
      Principal: {
        Service: "ecs-tasks.amazonaws.com"
      }
      Effect: "Allow"
    }]
  })

  inline_policy {
    name = "${var.project}-${var.env}-${var.app_name}-policy"
    
    policy = jsonencode({
      Version: "2012-10-17"
      Statement: [
        {
          "Effect": "Allow"
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow"
          "Action": [
            "s3:GetObject",
            "s3:PutObject"
          ]
          "Resource": "*"
        }
      ]    
    })
  }
}

resource "aws_iam_role_policy_attachment" "ecs-application-execution" {
  role       = aws_iam_role.ecs-application.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_service_discovery_service" "ecs-application" {
  name = var.app_name

  dns_config {
    namespace_id   = var.ecs-private-namespace_id
    routing_policy = "MULTIVALUE"

    dns_records {
      type = "A"
      ttl  = 5
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "ecs-application" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs-application.arn
  execution_role_arn       = aws_iam_role.ecs-application.arn
  requires_compatibilities = [ var.worker_ec2 ? "EC2" : "FARGATE" ]
  
  ### Resources
  cpu    = var.app_cpu
  memory = var.app_memory

  container_definitions = templatefile("${path.module}/application.json", {
    APP_NAME   = var.app_name,
    APP_PORT   = var.app_port,
    APP_IMAGE  = var.app_image,
    LOG_GROUP  = var.ecs-log-group_name,
    REGION     = var.region
  })
}

resource "aws_ecs_service" "ecs-application" {
  name                              = var.app_name
  cluster                           = var.ecs-cluster_arn
  task_definition                   = aws_ecs_task_definition.ecs-application.arn
  desired_count                     = var.app_desired_count
  scheduling_strategy               = "REPLICA"
  launch_type                       = var.worker_ec2 ? "EC2" : "FARGATE"
  health_check_grace_period_seconds = var.app_health_check_period

  network_configuration {
    assign_public_ip = false
    security_groups  = [ aws_security_group.ecs-application.id ]
    subnets          = [ var.subnet-private-a_id, var.subnet-private-b_id ]
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-application.arn
    container_name   = var.app_name
    container_port   = var.app_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ecs-application.arn
  }

  depends_on = [
    aws_alb_listener_rule.ecs-application # Wait for target group to be attached to ALB first
  ]
}

resource "aws_alb_target_group" "ecs-application" {
  name_prefix = var.app_name
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    interval            = 10
    matcher             = "200"
    path                = var.app_path
    protocol            = "HTTP"
    timeout             = 5
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "ecs-application" {
  listener_arn = var.alb-listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs-application.arn
  }

  condition {
    path_pattern {
      values = ["${var.app_path}*"]
    }
  }
}
