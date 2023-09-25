output "bastion-sg_id" {
    value = aws_security_group.bastion.id
}

output "bastion_id" {
    value = aws_instance.bastion.id
}
