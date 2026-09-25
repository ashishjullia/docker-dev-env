#!/usr/bin/env bash
# Temporary AWS credentials from an MFA code.
#
# Source this file so the new credentials stay in the current shell.
# The container shell provides `mfa` for that:
#   mfa 123456
#   source /usr/local/bin/mfa.sh 123456
#
# Running this file as a program cannot update the shell you are already in.

if [ -z "${1:-}" ]; then
    echo "Usage: mfa <MFA-TOKEN>" >&2
    return 1 2>/dev/null || exit 1
fi

session_duration=129600 # 36 hours, the STS maximum for GetSessionToken
mfa_code=$1
aws_dir="${HOME}/.aws"
aws_creds_file="${aws_dir}/credentials"
orig_creds_file="${aws_dir}/origcreds"
tmp_creds_file="${aws_dir}/tempcreds"

mkdir -p "$aws_dir"

if [ ! -f "$aws_creds_file" ]; then
    echo "AWS credentials not found at ${aws_creds_file}." >&2
    echo "Long-lived keys have to be configured before requesting an MFA session." >&2
    return 1 2>/dev/null || exit 1
fi

if [ ! -f "$orig_creds_file" ]; then
    echo "Backing up current credentials to ${orig_creds_file}"
    cp "$aws_creds_file" "$orig_creds_file"
    chmod 600 "$orig_creds_file"
fi

# Always call STS with the long-lived keys, not a previous session token.
cp "$orig_creds_file" "$aws_creds_file"
chmod 600 "$aws_creds_file"

mfa_device_code=$(aws iam list-mfa-devices | jq -r '.MFADevices[0].SerialNumber // empty')
if [ -z "$mfa_device_code" ]; then
    echo "Failed to retrieve an MFA device. Check that the AWS CLI is using the long-lived credentials." >&2
    return 1 2>/dev/null || exit 1
fi

echo "aws sts get-session-token --duration-seconds ${session_duration} --serial-number ${mfa_device_code} --token-code ${mfa_code}"
if ! aws sts get-session-token \
    --duration-seconds "$session_duration" \
    --serial-number "$mfa_device_code" \
    --token-code "$mfa_code" > "$tmp_creds_file"; then
    echo "Request failed" >&2
    return 1 2>/dev/null || exit 1
fi

access_key_id=$(jq -r '.Credentials.AccessKeyId // empty' "$tmp_creds_file")
secret_access_key=$(jq -r '.Credentials.SecretAccessKey // empty' "$tmp_creds_file")
session_token=$(jq -r '.Credentials.SessionToken // empty' "$tmp_creds_file")
expiry=$(jq -r '.Credentials.Expiration // empty' "$tmp_creds_file")

if [ -z "$access_key_id" ] || [ -z "$secret_access_key" ] || [ -z "$session_token" ]; then
    echo "Request failed" >&2
    return 1 2>/dev/null || exit 1
fi

cat > "$aws_creds_file" << EOF
[default]
aws_access_key_id = ${access_key_id}
aws_secret_access_key = ${secret_access_key}
aws_session_token = ${session_token}
EOF
chmod 600 "$aws_creds_file"
rm -f "$tmp_creds_file"

# Environment variables override the credentials file, including keys that
# Portunus already exported, so these have to be set in this shell.
export AWS_ACCESS_KEY_ID="$access_key_id"
export AWS_SECRET_ACCESS_KEY="$secret_access_key"
export AWS_SESSION_TOKEN="$session_token"

if expiry_local=$(date -d "$expiry" 2>/dev/null); then
    echo "All set. Expiry at: ${expiry_local}"
else
    echo "All set. Expiry at: ${expiry}"
fi
echo "Session credentials are exported and written to ${aws_creds_file}."
