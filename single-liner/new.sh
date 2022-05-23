#!/bin/bash
tfenv install ${TF_VERSION} 
tfenv use ${TF_VERSION}  
aws configure set region us-east-1
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws eks update-kubeconfig --region us-east-1 --name ${NAME_OF_CLUSTER}
/bin/bash