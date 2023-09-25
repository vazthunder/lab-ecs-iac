output "vpc_id" {
    value = aws_vpc.main.id
}

output "subnet-public-a_id" {
    value = aws_subnet.public-a.id
}

output "subnet-public-b_id" {
    value = aws_subnet.public-b.id
}

output "subnet-private-a_id" {
    value = aws_subnet.private-a.id
}

output "subnet-private-b_id" {
    value = aws_subnet.private-b.id
}
