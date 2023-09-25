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

echo -e "\n[+] Deleting environment...\n"
docker run --rm -ti -v $(pwd)/.aws:/root/.aws -v $(pwd):/terraform -w /terraform \
    hashicorp/terraform destroy -var-file=$ENVIRONMENT.tfvars

echo -e "\n[+] Finished.\n"
