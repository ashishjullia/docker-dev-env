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
    # When AWS_ROLE_TO_ASSUME is also set, the IAM user keys are stored outside the
    # AWS credentials file. The default profile can only obtain credentials by
    # assuming that role, and a failed assume fails the command.
    if [ -n "${AWS_REGION}" ] && [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "Configuring AWS with region: ${AWS_REGION}"
        if [ -n "${AWS_ROLE_TO_ASSUME}" ]; then
            mkdir -p "${HOME}/.aws"
            chmod 700 "${HOME}/.aws"
            jq -n \
                --arg RoleArn "$AWS_ROLE_TO_ASSUME" \
                --arg AccessKeyId "$AWS_ACCESS_KEY_ID" \
                --arg SecretAccessKey "$AWS_SECRET_ACCESS_KEY" \
                --arg SessionToken "${AWS_SESSION_TOKEN:-}" \
                '{RoleArn:$RoleArn, AccessKeyId:$AccessKeyId, SecretAccessKey:$SecretAccessKey, SessionToken:$SessionToken}' \
                > "${HOME}/.aws/role-source.json" || error_exit "Failed to store role source credentials."
            chmod 600 "${HOME}/.aws/role-source.json"
            # A default access key in this file wins over the role and would run commands as the IAM user.
            rm -f "${HOME}/.aws/credentials"
            cat > "${HOME}/.aws/config" << EOF
[default]
region = ${AWS_REGION}
credential_process = /usr/local/bin/aws-role-credentials
EOF
            chmod 600 "${HOME}/.aws/config"
            unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN \
                AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SHARED_CREDENTIALS_FILE AWS_CONFIG_FILE \
                AWS_CONTAINER_CREDENTIALS_RELATIVE_URI AWS_CONTAINER_CREDENTIALS_FULL_URI \
                AWS_CONTAINER_AUTHORIZATION_TOKEN AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE \
                AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_ARN AWS_ROLE_SESSION_NAME AWS_CREDENTIAL_EXPIRATION
            # AWS_MFA_SERIAL comes from this Portunus project. The one-time code does not.
            if [ -n "${AWS_MFA_SERIAL:-}" ]; then
                echo "MFA is required before assuming ${AWS_ROLE_TO_ASSUME}."
                # read -p writes the prompt to stderr. Discarding stderr hides it and looks like a hang.
                if [ -r /dev/tty ] && [ -w /dev/tty ]; then
                    printf 'MFA code: ' >/dev/tty
                    IFS= read -r mfa_code </dev/tty || error_exit "AWS_MFA_SERIAL is set for this project, but the MFA code could not be read."
                else
                    printf 'MFA code: ' >&2
                    IFS= read -r mfa_code || error_exit "AWS_MFA_SERIAL is set for this project, but there is no terminal to read an MFA code."
                fi
                if [ -z "${mfa_code}" ]; then
                    error_exit "An MFA code is required to assume ${AWS_ROLE_TO_ASSUME}."
                fi
                /usr/local/bin/aws-mfa-session "$AWS_MFA_SERIAL" "$mfa_code" >/dev/null || error_exit "Failed to create an MFA session for ${AWS_ROLE_TO_ASSUME}."
            fi
            caller_arn=$(aws sts get-caller-identity --query Arn --output text) || error_exit "Failed to assume role: ${AWS_ROLE_TO_ASSUME}. If this account requires MFA, set AWS_MFA_SERIAL on this Portunus project."
            role_name=${AWS_ROLE_TO_ASSUME##*/}
            case "$caller_arn" in
                arn:aws:sts::*:assumed-role/${role_name}/*) ;;
                *) error_exit "Refusing to open a shell. AWS CLI resolved to ${caller_arn}, not assumed role ${AWS_ROLE_TO_ASSUME}." ;;
            esac
            expiry=""
            if [ -f "${HOME}/.aws/role-expiration" ]; then
                expiry=$(cat "${HOME}/.aws/role-expiration")
            fi
            if [ -n "$expiry" ] && expiry_local=$(date -d "$expiry" 2>/dev/null); then
                expiry_display=$expiry_local
            else
                expiry_display=${expiry:-unknown}
            fi
            echo "Assumed role ${AWS_ROLE_TO_ASSUME}"
            echo "Caller: ${caller_arn}"
            echo "Session expires at: ${expiry_display}. The AWS CLI assumes this role again when it expires."
            echo "Commands will not run with the IAM user keys. If the role cannot be assumed, the command fails."
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
