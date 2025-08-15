#!/bin/bash
set -e

# --- SCRIPT ARGUMENTS ---
JSON_FILE=$1
ACCOUNT_ID=$2
ACTION=$3
WORK_DIR=$4

# --- VALIDATION ---
if [[ ! -f "$JSON_FILE" ]]; then
    echo "❌ File $JSON_FILE not found!"
    exit 1
fi

echo "🚀 Executing terraform $ACTION for account $ACCOUNT_ID"
echo "📁 Working directory: $WORK_DIR"

cd "$WORK_DIR"

if [[ ! -f "main.tf" ]]; then
    echo "❌ main.tf not found in $WORK_DIR!"
    exit 1
fi

# --- VARIABLE PREPARATION ---
echo "📝 Isolating configuration for account $ACCOUNT_ID..."
ACCOUNT_JSON=$(jq --arg account_id "$ACCOUNT_ID" '. | .[$account_id]' "$JSON_FILE")

if [[ -z "$ACCOUNT_JSON" ]]; then
    echo "❌ Could not find account with ID '$ACCOUNT_ID' in $JSON_FILE"
    exit 1
fi

echo "📝 Generating terraform variables file..."

# [THE FIX] This jq command modifies the account JSON in place.
# It renames ssh_public_key, transforms block_volumes, and then removes
# any keys that are not valid Terraform variables for this module.
echo "$ACCOUNT_JSON" | jq '
  # 1. Rename ssh_public_key to ssh_key
  .ssh_key = .ssh_public_key |
  # 2. Transform block_volumes array into the required map
  .shared_volumes_config = ([(.block_volumes // [])[] | {key: .display_name | sub("-"; "_"), value: {display_name, size_in_gbs}}] | from_entries) |
  # 3. Delete keys that are not Terraform input variables
  del(.account_name, .availability_domain, .private_key, .ssh_public_key, .block_volumes, .tf_state_bucket_name, .namespace)
' > account.auto.tfvars.json


# --- PRIVATE KEY & BACKEND CONFIG ---
PRIVATE_KEY=$(echo "$ACCOUNT_JSON" | jq -r ".private_key")
echo "$PRIVATE_KEY" > private_key.pem
chmod 600 private_key.pem
echo "✅ Private key created"

# --- TERRAFORM INITIALIZATION ---
terraform init \
  -backend-config="bucket=$(echo "$ACCOUNT_JSON" | jq -r '.tf_state_bucket_name')" \
  -backend-config="namespace=$(echo "$ACCOUNT_JSON" | jq -r '.namespace')" \
  -backend-config="region=$(echo "$ACCOUNT_JSON" | jq -r '.region')" \
  -backend-config="tenancy_ocid=$(echo "$ACCOUNT_JSON" | jq -r '.tenancy_ocid')" \
  -backend-config="user_ocid=$(echo "$ACCOUNT_JSON" | jq -r '.user_ocid')" \
  -backend-config="fingerprint=$(echo "$ACCOUNT_JSON" | jq -r '.fingerprint')" \
  -backend-config="private_key_path=$(pwd)/private_key.pem" \
  -reconfigure

# --- TERRAFORM EXECUTION ---
echo "📋 Executing terraform $ACTION..."

AUTO_APPROVE=""
if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

terraform "$ACTION" $AUTO_APPROVE -var="private_key_path=$(pwd)/private_key.pem"

echo "✅ Terraform $ACTION completed successfully!"

# --- CLEANUP ---
echo "🧹 Cleaning up generated files..."
rm -f account.auto.tfvars.json
