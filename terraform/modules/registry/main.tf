resource "aws_ecr_repository" "private" {
  name                 = "${var.project}-${var.env}-${var.app_name}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Group = "${var.project}-${var.env}"
  }
}
