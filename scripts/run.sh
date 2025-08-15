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
# [CHANGED] We now build the variables file by selecting only the keys that
# are declared in variables.tf. This avoids all "undeclared variable" warnings.
# It also renames "ssh_public_key" from the JSON to "ssh_key" for Terraform.
echo "📝 Generating terraform variables file..."
jq --arg account_id "$ACCOUNT_ID" '
.[$account_id] | {
    compartment_ocid,
    image_ocid,
    ssh_key: .ssh_public_key, # Renames the key to match Terraform
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
    shared_volumes_config: .block_volumes # Passes the volumes data
}
' "$JSON_FILE" > account.auto.tfvars.json

# Extract private key separately for backend and file creation
PRIVATE_KEY=$(jq -r ".[\"$ACCOUNT_ID\"].private_key" "$JSON_FILE")
echo "$PRIVATE_KEY" > private_key.pem
chmod 600 private_key.pem
echo "✅ Private key created"

# --- TERRAFORM INITIALIZATION ---
# This part remains the same, using jq to get individual values for the backend config.
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

# The TERRAFORM_ARGS array is no longer needed. The only variable we must pass
# manually is private_key_path, as all others are in the auto.tfvars.json file.
AUTO_APPROVE=""
if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

terraform "$ACTION" $AUTO_APPROVE -var="private_key_path=$(pwd)/private_key.pem"

echo "✅ Terraform $ACTION completed successfully!"

# --- CLEANUP ---
echo "🧹 Cleaning up generated files..."
rm -f account.auto.tfvars.json
