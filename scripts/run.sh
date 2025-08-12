#!/bin/bash
set -e

JSON_FILE=$1
ACCOUNT_ID=$2
ACTION=$3
WORK_DIR=$4

if [[ ! -f "$JSON_FILE" ]]; then
    echo "❌ File $JSON_FILE not found!"
    exit 1
fi

echo "🚀 Executing terraform $ACTION for account $ACCOUNT_ID"
echo "📁 Working directory: $WORK_DIR"

get_value() {
    jq -r ".\"$ACCOUNT_ID\".\"$1\"" "$JSON_FILE" 2>/dev/null || echo ""
}

cd "$WORK_DIR"

if [[ ! -f "main.tf" ]]; then
    echo "❌ main.tf not found in $WORK_DIR!"
    exit 1
fi

prepare_boot_volume_param() {
    local boot_volume_size
    boot_volume_size=$(get_value "boot_volume_size_in_gbs")
    if [[ "$boot_volume_size" == "null" || -z "$boot_volume_size" ]]; then
        echo ""
    else
        echo "-var=boot_volume_size_in_gbs=$boot_volume_size"
    fi
}

PRIVATE_KEY=$(get_value "private_key")
echo "$PRIVATE_KEY" > private_key.pem
chmod 600 private_key.pem
echo "✅ Private key created"

AUTO_APPROVE=""
if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

TERRAFORM_ARGS=(
    -var="region=$(get_value region)"
    -var="compartment_ocid=$(get_value compartment_ocid)"
    -var="ad_number=$(get_value ad_number)"
    -var="prefix=$(get_value prefix)"
    -var="ssh_key=$(get_value ssh_key)"
    -var="vcn_cidr=$(get_value vcn_cidr)"
    -var="subnet_cidr=$(get_value subnet_cidr)"
    -var="image_ocid=$(get_value image_ocid)"
    -var="tenancy_ocid=$(get_value tenancy_ocid)"
    -var="user_ocid=$(get_value user_ocid)"
    -var="fingerprint=$(get_value fingerprint)"
    -var="private_key_path=$(pwd)/private_key.pem"
    -var="instance_count=$(get_value instance_count)"
    -var="instance_shape=$(get_value instance_shape)"
    -var="instance_memory_gb=$(get_value instance_memory_gb)"
    -var="instance_ocpus=$(get_value instance_ocpus)"
    $(prepare_boot_volume_param)
)

terraform init \
  -backend-config="bucket=$(get_value tf_state_bucket_name)" \
  -backend-config="namespace=$(get_value namespace)" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=$(get_value region)" \
  -backend-config="tenancy_ocid=$(get_value tenancy_ocid)" \
  -backend-config="user_ocid=$(get_value user_ocid)" \
  -backend-config="fingerprint=$(get_value fingerprint)" \
  -backend-config="private_key_path=$(pwd)/private_key.pem"

echo "📋 Executing terraform $ACTION..."
case $ACTION in
  plan)
    terraform plan "${TERRAFORM_ARGS[@]}"
    ;;
  apply|destroy)
    terraform "$ACTION" $AUTO_APPROVE "${TERRAFORM_ARGS[@]}"
    ;;
esac

echo "✅ Terraform $ACTION completed successfully!"
