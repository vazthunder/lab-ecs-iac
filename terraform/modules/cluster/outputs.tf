output "ecs-cluster_arn" {
    value = aws_ecs_cluster.main.arn
}

output "ecs-log-group_name" {
    value = aws_cloudwatch_log_group.ecs-cluster.name
}

output "ecs-private-namespace_id" {
    value = aws_service_discovery_private_dns_namespace.ecs-cluster.id
}
