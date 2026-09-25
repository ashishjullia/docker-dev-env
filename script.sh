#!/usr/bin/env bash

# Exit on any error, including a failed command in a pipeline
set -eo pipefail

# Function to print an error and exit
function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

# Only execute the following block if PORTUNUS_TOKEN is set
if [ -n "${PORTUNUS_TOKEN}" ]; then

    # Fetch and export environment variables from a given API
    portunus_env=$(print-env --api "https://portunusapiprod.ashishjullia.com/env" --format json | jq -r 'to_entries[] | "\(.key)=\(.value)"') || error_exit "Failed to fetch environment from Portunus"
    while IFS="=" read -r key value; do
        [ -n "$key" ] || continue
        export "$key=$(printf %b "$value")"
    done <<< "$portunus_env"

    # Conditionally install Terraform version if TF_VERSION is set
    if [ -n "${TF_VERSION}" ]; then
        echo "TF_VERSION is set to ${TF_VERSION}. Installing Terraform version: ${TF_VERSION}"
        tfenv install "$TF_VERSION" || error_exit "Failed to install Terraform version: ${TF_VERSION}"
        tfenv use "$TF_VERSION" || error_exit "Failed to switch to Terraform version: ${TF_VERSION}"
    else
        echo "TF_VERSION is not set. Skipping Terraform installation."
    fi

    # Conditionally configure AWS if AWS_REGION, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY are set.
    # When AWS_ROLE_TO_ASSUME is also set, keep the IAM user keys in the "source"
    # profile and make the default profile assume that role. The AWS CLI then
    # assumes the role again on its own after the session expires.
    if [ -n "${AWS_REGION}" ] && [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "Configuring AWS with region: ${AWS_REGION}"
        if [ -n "${AWS_ROLE_TO_ASSUME}" ]; then
            aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile source || error_exit "Failed to set AWS access key."
            aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile source || error_exit "Failed to set AWS secret access key."
            aws configure set region "$AWS_REGION" --profile source || error_exit "Failed to set AWS region: ${AWS_REGION}"
            if [ -n "${AWS_SESSION_TOKEN:-}" ]; then
                aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile source || error_exit "Failed to set AWS session token."
            fi
            aws configure set role_arn "$AWS_ROLE_TO_ASSUME" || error_exit "Failed to set role: ${AWS_ROLE_TO_ASSUME}"
            aws configure set source_profile source || error_exit "Failed to set source profile for role: ${AWS_ROLE_TO_ASSUME}"
            aws configure set region "$AWS_REGION" || error_exit "Failed to set AWS region: ${AWS_REGION}"
            # Environment credentials override the role profile, so drop the IAM user keys.
            unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
            caller_arn=$(aws sts get-caller-identity --query Arn --output text) || error_exit "Failed to assume role: ${AWS_ROLE_TO_ASSUME}"
            expiry=""
            if [ -d "${HOME}/.aws/cli/cache" ]; then
                for cache_file in "${HOME}/.aws/cli/cache"/*.json; do
                    [ -f "$cache_file" ] || continue
                    candidate=$(jq -r '.Credentials.Expiration // empty' "$cache_file")
                    [ -n "$candidate" ] && expiry=$candidate
                done
            fi
            if [ -n "$expiry" ] && expiry_local=$(date -d "$expiry" 2>/dev/null); then
                expiry_display=$expiry_local
            else
                expiry_display=${expiry:-unknown}
            fi
            echo "Assumed role ${AWS_ROLE_TO_ASSUME}"
            echo "Caller: ${caller_arn}"
            echo "Session expires at: ${expiry_display}. The AWS CLI assumes this role again when it expires."
            echo "Run dev with no project to start a container that does not assume this role."
        else
            aws configure set region "$AWS_REGION" || error_exit "Failed to set AWS region: ${AWS_REGION}"
            aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" || error_exit "Failed to set AWS access key."
            aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" || error_exit "Failed to set AWS secret access key."
        fi
    elif [ -n "${AWS_ROLE_TO_ASSUME:-}" ]; then
        error_exit "AWS_ROLE_TO_ASSUME is set, but AWS_REGION, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY are required to assume it."
    else
        echo "AWS configuration variables are not fully set. Skipping AWS configuration."
    fi

    # Update kubeconfig if a cluster name is provided
    if [[ -n "${NAME_OF_CLUSTER}" ]]; then
        aws eks update-kubeconfig --region "$AWS_REGION" --name "$NAME_OF_CLUSTER" || error_exit "Failed to update kubeconfig for cluster: ${NAME_OF_CLUSTER}"
    fi

    # Conditionally install Node.js version if NODE_VERSION is set
    if [ -n "${NODE_VERSION}" ]; then
        echo "NODE_VERSION is set to ${NODE_VERSION}. Installing Node.js version: ${NODE_VERSION}"
        export NVM_DIR="/usr/local/nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        nvm install "$NODE_VERSION"
    else
        echo "NODE_VERSION is not set. Skipping Node.js installation."
    fi

    # Authenticate GitHub CLI if GITHUB_TOKEN is provided
    if [ -n "${GH_CLI_TOKEN}" ]; then
        echo "Authenticating GitHub CLI..."
        gh auth login --with-token <<< "$GH_CLI_TOKEN"
        gh auth setup-git
    else
        echo "GH_CLI_TOKEN is not set. Skipping GitHub CLI authentication."
    fi

fi

# Exit to a bash prompt
/bin/bash
