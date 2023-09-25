resource "aws_ecs_capacity_provider" "managed-asg" {
  count = var.worker_ec2 ? 1 : 0

  name = "${var.project}-${var.env}-managed-asg"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs-worker[0].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-cluster"

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = [ 
    var.worker_ec2 ? aws_ecs_capacity_provider.managed-asg[0].name : "FARGATE" 
  ]
}

resource "aws_cloudwatch_log_group" "ecs-cluster" {
  name              = "/aws/ecs/${var.project}-${var.env}-cluster"
  retention_in_days = 14
}

resource "aws_service_discovery_private_dns_namespace" "ecs-cluster" {
  name = var.private_domain
  vpc  = var.vpc_id
}
