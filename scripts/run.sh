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

# --- VARIABLE PREPARATION (THE FINAL FIX) ---
# [CHANGED] The jq command now correctly transforms the 'block_volumes' list
# from your JSON into the 'shared_volumes_config' map that Terraform expects.
# This resolves the hidden data type conflict that was causing the null error.
echo "📝 Generating terraform variables file..."
jq --arg account_id "$ACCOUNT_ID" '
.[$account_id] | {
    # All other variables are passed directly
    compartment_ocid,
    image_ocid,
    ssh_key: .ssh_public_key, # Renames key for Terraform
    region,
    prefix,
    tenancy_ocid,
    user_ocid,
    fingerprint,
    instance_count,
    instance_shape,
    instance_memory_gb,
    instance_ocpus,
    boot_volume_size_in_gbs,
    ad_number,
    vcn_cidr,
    subnet_cidr,
    # This line transforms the list into a map using the display_name as the key
    shared_volumes_config: ([.block_volumes[] | {key: .display_name | sub("-"; "_"), value: {display_name, size_in_gbs}}] | from_entries)
}
' "$JSON_FILE" > account.auto.tfvars.json

# Extract private key separately for backend and file creation
PRIVATE_KEY=$(jq -r ".[\"$ACCOUNT_ID\"].private_key" "$JSON_FILE")
echo "$PRIVATE_KEY" > private_key.pem
chmod 600 private_key.pem
echo "✅ Private key created"

# --- TERRAFORM INITIALIZATION ---
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

AUTO_APPROVE=""
if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

terraform "$ACTION" $AUTO_APPROVE -var="private_key_path=$(pwd)/private_key.pem"

echo "✅ Terraform $ACTION completed successfully!"

# --- CLEANUP ---
echo "🧹 Cleaning up generated files..."
rm -f account.auto.tfvars.json
