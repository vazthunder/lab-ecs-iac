# QuanTH | Container stack Terraform template

<br>

## 0. Preparation

- Install Docker on your machine.
- Create your AWS user with AdministratorAccess permission. 
- Generate access/secret key pair for your user.
- Create a private S3 bucket to store Terraform state file.

<br>

## 1. Create AWS configuration files

```console
$ vim .aws/config

[default]
region=ap-southeast-2
output=json

$ vim .aws/credentials

[default]
aws_access_key_id=AKIASIZ63U6TUEXAMPLE
aws_secret_access_key=vipLAJj3aFUlWt5+HuieBuQQ3S2w7BcKCEXAMPLE
```

<br>

## 2. Create environment variable file

```console
$ cp env.tfvars prod.tfvars
$ vim prod.tfvars

project = "myproj"
env     = "dev"
region  = "us-west-2"
[...]
```

<br>

## 3. Build Terraform stack

```console
$ cp env.build.sh prod.build.sh
$ vim prod.build.sh

DEPLOY_BUCKET="xxxxxxxxxxxxxx"
PROJECT_NAME="myproj"
ENVIRONMENT="prod"
[...]

$ chmod +x prod.build.sh
$ ./prod.build.sh
```

<br>

## 4. Destroy Terraform stack

```console
$ cp env.destroy.sh prod.destroy.sh
$ vim prod.destroy.sh

DEPLOY_BUCKET="xxxxxxxxxxxxxx"
PROJECT_NAME="myproj"
ENVIRONMENT="prod"
[...]

$ chmod +x prod.destroy.sh
$ ./prod.destroy.sh
```
