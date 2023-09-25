terraform {
  backend "s3" { }
}

provider "aws" { }

### Static resources

module "network" {
  source = "./modules/network"

  region         = var.region
  project        = var.project
  env            = var.env
  cidr_vpc       = var.cidr_vpc
  cidr_private_a = var.cidr_private_a
  cidr_private_b = var.cidr_private_b
  cidr_public_a  = var.cidr_public_a
  cidr_public_b  = var.cidr_public_b
}

module "bastion" {
  source = "./modules/bastion"

  project               = var.project
  env                   = var.env
  bastion_ami_id        = var.bastion_ami_id
  bastion_instance_type = var.bastion_instance_type
  bastion_storage_size  = var.bastion_storage_size
  key_name              = var.key_name
  vpc_id                = module.network.vpc_id
  subnet-public-a_id    = module.network.subnet-public-a_id
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project            = var.project
  env                = var.env
  vpc_id             = module.network.vpc_id
  subnet-public-a_id = module.network.subnet-public-a_id
  subnet-public-b_id = module.network.subnet-public-b_id
}

module "cluster" {
  source = "./modules/cluster"
  
  project              = var.project
  env                  = var.env
  private_domain       = var.private_domain
  worker_ec2           = var.worker_ec2
  worker_instance_type = var.worker_instance_type
  worker_storage_size  = var.worker_storage_size
  worker_max_size      = var.worker_max_size
  key_name             = var.key_name
  vpc_id               = module.network.vpc_id
  subnet-private-a_id  = module.network.subnet-private-a_id
  subnet-private-b_id  = module.network.subnet-private-b_id
  bastion-sg_id        = module.bastion.bastion-sg_id
}

### Dynamic resources

module "repo_app" {
  source = "./modules/registry"
  
  project  = var.project
  env      = var.env
  app_name = "app"
}

module "app" {
  source = "./modules/application"

  project                  = var.project
  env                      = var.env
  region                   = var.region
  cidr_vpc                 = var.cidr_vpc
  worker_ec2               = var.worker_ec2
  vpc_id                   = module.network.vpc_id
  subnet-private-a_id      = module.network.subnet-private-a_id
  subnet-private-b_id      = module.network.subnet-private-b_id
  alb-sg_id                = module.loadbalancer.alb-sg_id
  alb-listener_arn         = module.loadbalancer.alb-listener-http_arn
  ecs-cluster_arn          = module.cluster.ecs-cluster_arn
  ecs-log-group_name       = module.cluster.ecs-log-group_name
  ecs-private-namespace_id = module.cluster.ecs-private-namespace_id

  app_name                = "app"
  app_image               = "615929987729.dkr.ecr.us-east-2.amazonaws.com/lab-ecs-test-app:latest"
  app_port                = 3000
  app_path                = "/"
  app_cpu                 = 256
  app_memory              = 512
  app_desired_count       = 2
  app_health_check_period = 15
}
