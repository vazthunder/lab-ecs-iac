#!/bin/bash -ex

################################## VARIABLES #############################################

BACKEND_BUCKET=""
AWS_REGION=""
AWS_PROFILE=""
PROJECT_NAME=""
ENVIRONMENT=""

#########################################################################################


### Execute

echo -e "\n[+] Initializing Terraform...\n"
docker run --rm -ti -v $(pwd)/.aws:/root/.aws -v $(pwd):/terraform -w /terraform \
    hashicorp/terraform init \
        -reconfigure \
        -backend=true \
        -backend-config="bucket=$BACKEND_BUCKET" \
        -backend-config="key=$PROJECT_NAME/$ENVIRONMENT/terraform.tfstate" \
        -backend-config="region=$AWS_REGION" \
        -backend-config="profile=$AWS_PROFILE"

echo -e "\n[+] Validating configurations...\n"
docker run --rm -ti -v $(pwd)/.aws:/root/.aws -v $(pwd):/terraform -w /terraform \
    hashicorp/terraform plan -var-file=$ENVIRONMENT.tfvars -out=$ENVIRONMENT.tfplan

read -p $'\nPress ENTER to continue to deploy, or CTRL-C to cancel...\n'

echo -e "\n[+] Deploying environment...\n"
docker run --rm -ti -v $(pwd)/.aws:/root/.aws -v $(pwd):/terraform -w /terraform \
    hashicorp/terraform apply $ENVIRONMENT.tfplan

echo -e "\n[+] Finished.\n"
