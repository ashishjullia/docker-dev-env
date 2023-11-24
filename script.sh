#!/usr/bin/env bash

# Exit on any error
set -e

# Function to print an error and exit
function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

# Only execute the following block if PORTUNUS_TOKEN is set
if [ -n "${PORTUNUS_TOKEN}" ]; then

    # Fetch and export environment variables from a given API
    while IFS="=" read -r key value; do 
        export "$key=$(printf %b "$value")"
    done < <(print-env --api "https://portunusapiprod.ashishjullia.com/env" --format json | jq -r 'to_entries[] | "\(.key)=\(.value)"')

    # Conditionally install Terraform version if TF_VERSION is set
    if [ -n "${TF_VERSION}" ]; then
        echo "TF_VERSION is set to ${TF_VERSION}. Installing Terraform version: ${TF_VERSION}"
        tfenv install "$TF_VERSION" || error_exit "Failed to install Terraform version: ${TF_VERSION}"
        tfenv use "$TF_VERSION" || error_exit "Failed to switch to Terraform version: ${TF_VERSION}"
    else
        echo "TF_VERSION is not set. Skipping Terraform installation."
    fi

    # Conditionally configure AWS if AWS_REGION, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY are set
    if [ -n "${AWS_REGION}" ] && [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "Configuring AWS with region: ${AWS_REGION}"
        aws configure set region "$AWS_REGION" || error_exit "Failed to set AWS region: ${AWS_REGION}"
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" || error_exit "Failed to set AWS access key."
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" || error_exit "Failed to set AWS secret access key."
    else
        echo "AWS configuration variables are not fully set. Skipping AWS configuration."
    fi

    # Update kubeconfig if a cluster name is provided
    if [[ -n "${NAME_OF_CLUSTER}" ]]; then
        aws eks update-kubeconfig --region "$AWS_REGION" --name "$NAME_OF_CLUSTER" || error_exit "Failed to update kubeconfig for cluster: ${NAME_OF_CLUSTER}"
    fi

    # Install specified Flux version if provided
    if [[ -n "$FLUX_VERSION" ]]; then
        echo "Installing Flux version: ${FLUX_VERSION}"
        curl -s https://fluxcd.io/install.sh | bash || error_exit "Failed to install Flux version: ${FLUX_VERSION}"
    fi

    # Conditionally install Node.js version if NODE_VERSION is set
    if [ -n "${NODE_VERSION}" ]; then
        echo "NODE_VERSION is set to ${NODE_VERSION}. Installing Node.js version: ${NODE_VERSION}"
        export NVM_DIR="/usr/local/nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        nvm install $NODE_VERSION
    else
        echo "NODE_VERSION is not set. Skipping Node.js installation."
    fi

    # Authenticate GitHub CLI if GITHUB_TOKEN is provided
    if [ -n "${GH_CLI_TOKEN}" ]; then
        echo "Authenticating GitHub CLI..."
        gh auth login --with-token <<< $GH_CLI_TOKEN 
        gh auth setup-git
    else
        echo "GH_CLI_TOKEN is not set. Skipping GitHub CLI authentication."
    fi

fi

# Exit to a bash prompt
/bin/bash
