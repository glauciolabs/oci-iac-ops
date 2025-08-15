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
echo "📝 Isolating configuration for account $ACCOUNT_ID..."

# [THE FIX] First, we robustly extract the entire JSON object for the selected account.
# This avoids the direct indexing '.[$account_id]' which was causing the error.
ACCOUNT_JSON=$(jq --arg account_id "$ACCOUNT_ID" 'to_entries | .[] | select(.key == $account_id) | .value' "$JSON_FILE")

if [[ -z "$ACCOUNT_JSON" ]]; then
    echo "❌ Could not find account with ID '$ACCOUNT_ID' in $JSON_FILE"
    exit 1
fi

echo "📝 Generating terraform variables file..."

# Now, we build the variables file using the isolated ACCOUNT_JSON.
echo "$ACCOUNT_JSON" | jq '{
    compartment_ocid,
    image_ocid,
    ssh_key: .ssh_public_key,
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
    shared_volumes_config: ([(.block_volumes // [])[] | {key: .display_name | sub("-"; "_"), value: {display_name, size_in_gbs}}] | from_entries)
}' > account.auto.tfvars.json


# --- PRIVATE KEY & BACKEND CONFIG ---
# [THE FIX] We now use the isolated ACCOUNT_JSON variable, which is cleaner and safer.
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
