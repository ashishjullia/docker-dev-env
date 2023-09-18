#!/usr/bin/env bash

# Exit on any error
set -e

# Function to print an error and exit
function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

# Check for dependencies
for cmd in jq tfenv aws curl print-env; do
    command -v "$cmd" >/dev/null 2>&1 || error_exit "$cmd is required but not installed."
done

# Ensure PORTUNUS_TOKEN is set
[[ -z "${PORTUNUS_TOKEN}" ]] && error_exit "PORTUNUS_TOKEN is not set."

# Fetch and export environment variables from a given API
while IFS="=" read -r key value; do 
    export "$key=$(printf %b "$value")"
done < <(print-env --api "https://portunusapiprod.ashishjullia.com/env" --format json | jq -r 'to_entries[] | "\(.key)=\(.value)"')

# Install the specified Terraform version or default to the latest
TF_VERSION="${TF_VERSION:-latest}"
echo "Installing Terraform version: ${TF_VERSION}"
tfenv install "$TF_VERSION" || error_exit "Failed to install Terraform version: ${TF_VERSION}"
tfenv use "$TF_VERSION" || error_exit "Failed to switch to Terraform version: ${TF_VERSION}"

# Configure AWS with the specified or default credentials
AWS_REGION="${AWS_REGION:-us-west-1}"  # Consider adding a default if appropriate
echo "Configuring AWS with region: ${AWS_REGION}"
aws configure set region "$AWS_REGION" || error_exit "Failed to set AWS region: ${AWS_REGION}"
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" || error_exit "Failed to set AWS access key."
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" || error_exit "Failed to set AWS secret access key."

# Update kubeconfig if a cluster name is provided
if [[ -n "${NAME_OF_CLUSTER}" ]]; then
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$NAME_OF_CLUSTER" || error_exit "Failed to update kubeconfig for cluster: ${NAME_OF_CLUSTER}"
fi

# Install specified Flux version if provided
if [[ -n "$FLUX_VERSION" ]]; then
    echo "Installing Flux version: ${FLUX_VERSION}"
    curl -s https://fluxcd.io/install.sh | bash || error_exit "Failed to install Flux version: ${FLUX_VERSION}"
fi

# Exit to a bash prompt
/bin/bash
