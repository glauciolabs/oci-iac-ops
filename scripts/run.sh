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

# --- VARIABLE PREPARATION (THE FIX) ---
# [CHANGED] Instead of extracting each variable one-by-one, we extract the entire
# JSON object for the selected account. This preserves all data types (string, number, null).
# Terraform will automatically load any file ending in .auto.tfvars.json.
echo "📝 Generating terraform variables file..."
jq ".[\"$ACCOUNT_ID\"]" "$JSON_FILE" > account.auto.tfvars.json

# [CHANGED] We still need to get the private key and some backend values separately.
PRIVATE_KEY=$(jq -r ".[\"$ACCOUNT_ID\"].private_key" "$JSON_FILE")
echo "$PRIVATE_KEY" > private_key.pem
chmod 600 private_key.pem
echo "✅ Private key created"

# --- TERRAFORM INITIALIZATION ---
# This part remains mostly the same, using jq to get individual values for the backend config.
terraform init \
  -backend-config="bucket=$(jq -r ".[\"$ACCOUNT_ID\"].tf_state_bucket_name" "$JSON_FILE")" \
  -backend-config="namespace=$(jq -r ".[\"$ACCOUNT_ID\"].namespace" "$JSON_FILE")" \
  -backend-config="region=$(jq -r ".[\"$ACCOUNT_ID\"].region" "$JSON_FILE")" \
  -backend-config="tenancy_ocid=$(jq -r ".[\"$ACCOUNT_ID\"].tenancy_ocid" "$JSON_FILE")" \
  -backend-config="user_ocid=$(jq -r ".[\"$ACCOUNT_ID\"].user_ocid" "$JSON_FILE")" \
  -backend-config="fingerprint=$(jq -r ".[\"$ACCOUNT_ID\"].fingerprint" "$JSON_FILE")" \
  -backend-config="private_key_path=$(pwd)/private_key.pem" \
  -reconfigure

# --- TERRAFORM EXECUTION ---
echo "📋 Executing terraform $ACTION..."

# [CHANGED] The large TERRAFORM_ARGS array is no longer needed.
# The only variable we need to pass manually is the one not in the JSON: private_key_path.
# All other variables (ad_number, region, etc.) are loaded from account.auto.tfvars.json.
AUTO_APPROVE=""
if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

terraform "$ACTION" $AUTO_APPROVE -var="private_key_path=$(pwd)/private_key.pem"

echo "✅ Terraform $ACTION completed successfully!"

# --- CLEANUP ---
# [ADDED] It's good practice to clean up the generated tfvars file.
echo "🧹 Cleaning up generated files..."
rm -f account.auto.tfvars.json
