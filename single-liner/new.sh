#!/bin/bash
tfenv install $TF_VERSION
tfenv use $TF_VERSION
aws configure set region $AWS_REGION
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws eks update-kubeconfig --region us-east-1 --name $NAME_OF_CLUSTER

#Extra Utilities. 
#If value of the corresponding env variable is not set, it will not be installed.
############ FLUX CLI ##############
if [[ -n "$FLUX_VERSION" ]]; then
    curl -s https://fluxcd.io/install.sh | bash
fi

/bin/bash