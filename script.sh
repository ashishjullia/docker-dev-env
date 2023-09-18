#!/usr/bin/env bash
# This shebang is more portable and will find bash wherever it's located in the system.

# Set script to exit on error or if an undefined variable is used
set -eu

# Function to print an error message and exit the script
# Arguments:
#   1. Error message (required)
#   2. Exit status code (optional; default is 1)
function error_exit {
    # Print the error message to stderr
    echo "$1" >&2
    # Exit the script with the provided status code, or 1 if none was provided
    exit "${2:-1}"
}

while IFS="=" read -r key value; do export "$key=$(printf %b "$value")"; done < <(print-env --api https://portunusapiprod.ashishjullia.com/env --format json | jq -r 'to_entries[] | "\(.key)=\(.value)"')

# Check if the necessary environment variables are set, and exit with an error message if they're not
[[ -z "${PORTUNUS_TOKEN}" ]] && error_exit "PORTUNUS_TOKEN is not set."

# If TF_VERSION is set, use that. Otherwise, default to the latest version
TF_VERSION="${TF_VERSION:-latest}"
echo "Installing Terraform version: ${TF_VERSION}"
tfenv install $TF_VERSION || error_exit "Failed to install Terraform version: ${TF_VERSION}"
tfenv use $TF_VERSION || error_exit "Failed to switch to Terraform version: ${TF_VERSION}"

# Configure AWS
echo "Configuring AWS with region: ${AWS_REGION}"
# Set the AWS region, and exit with an error message if the command fails
aws configure set region $AWS_REGION || error_exit "Failed to set AWS region: ${AWS_REGION}"
# Set the AWS access key, and exit with an error message if the command fails
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID || error_exit "Failed to set AWS access key."
# Set the AWS secret access key, and exit with an error message if the command fails
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY || error_exit "Failed to set AWS secret access key."

# Update the kubeconfig for the specified cluster if NAME_OF_CLUSTER is set
if [[ -n "${NAME_OF_CLUSTER}" ]]; then
    aws eks update-kubeconfig --region $AWS_REGION --name $NAME_OF_CLUSTER || error_exit "Failed to update kubeconfig for cluster: ${NAME_OF_CLUSTER}"
fi

# If the FLUX_VERSION environment variable is set, install that version of Flux
if [[ -n "$FLUX_VERSION" ]]; then
    echo "Installing Flux version: ${FLUX_VERSION}"
    # Download and run the Flux installation script, and exit with an error message if the command fails
    curl -s https://fluxcd.io/install.sh | bash || error_exit "Failed to install Flux version: ${FLUX_VERSION}"
fi

/bin/bash
