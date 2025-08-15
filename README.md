# Terraform OCI Multi-Account Infrastructure

A comprehensive Terraform solution for deploying Oracle Cloud Infrastructure (OCI) resources across multiple accounts using GitHub Actions automation, a modular architecture, native OCI backend state management, and flexible instance and volume configuration.

## 🏗️ Architecture

This solution offers:

* **Multi-Account Support**: Deploy infrastructure to different OCI accounts using a centralized JSON configuration.
* **Modular Design**: Reusable Terraform modules for networking, compute instances, and shared block volumes.
* **GitHub Actions Integration**: Automated deployment workflows with secure secret management.
* **Native OCI Backend**: Remote state storage using OCI Object Storage for enhanced security and collaboration.
* **Flexible Configuration**: Dynamic per-account definition of instance count, shapes, CPU, memory, and block volumes.
* **Cost Optimization**: Allows for different resource allocations for production, development, and testing environments.


## 📁 Project Structure

```
.
├── accounts/
│   ├── main.tf                     # Main Terraform configuration that orchestrates the modules
│   └── variables.tf                # Root module variable definitions
├── modules/
│   ├── oci-ampere-instance/        # Module for flexible compute instances
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── oci-network/                # Module for VCN, subnets, gateways, and security lists
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── oci-shared-volumes/         # Module for shareable block volumes
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── oci-terraform-backend/      # (Optional) Module to create the backend bucket
│       ├── main.tf
│       └── variables.tf
├── scripts/
│   └── run.sh                      # Main execution script for CI/CD and local use
└── .github/
    └── workflows/
        └── terraform.yml           # GitHub Actions workflow
```


## 🔧 Prerequisites \& Initial Setup

### **1. Oracle Cloud Infrastructure Account**

* An active OCI account with administrator access.


### **2. OCI Resource Setup**

* **Object Storage Bucket**: Create a bucket to store the Terraform state remotely. Enabling versioning is recommended.
* **API Key**: Generate an API key pair for your OCI user to allow Terraform to authenticate securely. You will need the **fingerprint**, **user OCID**, **tenancy OCID**, and the content of the **private key**.
* **Compartment**: Have a designated compartment for your resources and copy its **OCID**.


## ⚙️ Configuration

### **1. Account Configuration JSON**

Create a JSON file with the details for each account, including the flexible instance and volume configuration.

```json
{
  "1": {
    "account_name": "production",
    "ad_number": 1,
    "compartment_ocid": "ocid1.compartment.oc1..aaaaaaaabbbbbbbccccccddddddd",
    "fingerprint": "12:34:56:78:9a:bc:de:f0:12:34:56:78:9a:bc:de:f0",
    "image_ocid": "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaath3bwke2i3zu3sgxrgnsboacjihmylxbuogivbgma476pzykarpa",
    "namespace": "abcd1234efgh",
    "prefix": "prod",
    "region": "sa-saopaulo-1",
    "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...",
    "subnet_cidr": "10.0.1.0/24",
    "tenancy_ocid": "ocid1.tenancy.oc1..aaaaaaaabbbbbbbccccccddddddd",
    "tf_state_bucket_name": "terraform-state-prod",
    "user_ocid": "ocid1.user.oc1..aaaaaaaabbbbbbbccccccddddddd",
    "vcn_cidr": "10.0.0.0/16",
    "private_key": "-----BEGIN PRIVATE KEY-----\\n[YOUR_PRIVATE_KEY_CONTENT]\\n-----END PRIVATE KEY-----",
    "instance_count": 3,
    "instance_shape": "VM.Standard.A1.Flex",
    "instance_memory_gb": 24,
    "instance_ocpus": 4,
    "boot_volume_size_in_gbs": null,
    "block_volumes": [
      {
        "display_name": "database-storage",
        "size_in_gbs": 50
      },
      {
        "display_name": "file-storage",
        "size_in_gbs": 100
      }
    ]
  },
  "2": {
    "account_name": "development",
    "ad_number": 1,
    "compartment_ocid": "ocid1.compartment.oc1..eeeeeeeffffffffgggggghhhhhhh",
    "fingerprint": "98:76:54:32:10:fe:dc:ba:98:76:54:32:10:fe:dc:ba",
    "image_ocid": "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaath3bwke2i3zu3sgxrgnsboacjihmylxbuogivbgma476pzykarpa",
    "namespace": "abcd1234efgh",
    "prefix": "dev",
    "region": "sa-saopaulo-1",
    "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...",
    "subnet_cidr": "10.1.1.0/24",
    "tenancy_ocid": "ocid1.tenancy.oc1..aaaaaaaabbbbbbbccccccddddddd",
    "tf_state_bucket_name": "terraform-state-dev",
    "user_ocid": "ocid1.user.oc1..eeeeeeeffffffffgggggghhhhhhh",
    "vcn_cidr": "10.1.0.0/16",
    "private_key": "-----BEGIN PRIVATE KEY-----\\n[YOUR_DEV_PRIVATE_KEY_CONTENT]\\n-----END PRIVATE KEY-----",
    "instance_count": 1,
    "instance_shape": "VM.Standard.A1.Flex",
    "instance_memory_gb": 6,
    "instance_ocpus": 1,
    "boot_volume_size_in_gbs": null,
    "block_volumes": [
      {
        "display_name": "dev-data-storage",
        "size_in_gbs": 25
      }
    ]
  }
}
```


### **2. GitHub Secrets Setup**

1. **Encode the JSON**: Convert your JSON configuration file into a single-line Base64 string.

```bash
cat config.json | base64 -w 0
```

2. **Add to GitHub**: Go to your repository's **Settings → Secrets and variables → Actions** and create a new repository secret named `OCI_ACCOUNTS_JSON` with the Base64 string as its value.

## 🚀 Usage

### **GitHub Actions Deployment**

1. Navigate to the **Actions** tab in your GitHub repository.
2. Select the **Terraform OCI Multi-Account** workflow.
3. Click **Run workflow**.
4. Configure the parameters:
    * **Account Number**: Select the target account (1, 2, 3, etc.).
    * **Operation**: Choose `plan`, `apply`, or `destroy`.
5. Monitor the execution in the Actions logs.

### **Local Development**

1. Grant execute permission to the script: `chmod +x ./scripts/run.sh`.
2. Run Terraform operations from the project root:

```bash
# Run a plan on account 1
./scripts/run.sh config.json 1 plan ./accounts

# Run an apply on account 1
./scripts/run.sh config.json 1 apply ./accounts
```


## 🏛️ Infrastructure Details

### **Network Configuration**

* **VCN**: A Virtual Cloud Network with a custom CIDR per environment.
* **Public Subnet**: An internet-accessible subnet where instances are provisioned with public IPs.
* **Internet Gateway**: Provides internet access for the subnet.
* **Route Table**: Directs traffic from the subnet to the Internet Gateway.
* **Security Lists**: Allow SSH (22), HTTP (80), and HTTPS (443) traffic by default.


### **Compute and Storage Configuration**

* **Dynamic Instance Count**: Deploy 1 to N instances per environment.
* **Configurable Resources**: Memory (1-64 GB) and OCPUs (1-24) are configurable per instance.
* **Shared Block Volumes**: Create one or more block volumes and automatically attach them to all created instances, ideal for shared data like databases or files.
* **Access**: SSH key-based authentication.


## 🛠️ Customization

### **Adding New Accounts**

Add new account configurations to your JSON file with unique keys (e.g., "3", "4", etc.).

### **Configuration Options**

Configure resources per account using these parameters in the JSON:

* `instance_count`: Number of instances.
* `instance_shape`: The OCI instance shape.
* `instance_memory_gb`: Memory allocation (for Flex shapes).
* `instance_ocpus`: OCPU allocation (for Flex shapes).
* `block_volumes`: A list of objects, each defining a `display_name` and `size_in_gbs` for a block volume.


## 🔐 Security Features

* **Encrypted Private Key**: Keys are stored securely in encrypted GitHub Secrets.
* **Temporary File Cleanup**: Sensitive files, like the private key, are automatically removed after the pipeline runs.
* **Secure Authentication**: Uses OCI's API key authentication.
* **Encrypted State**: Remote state is stored securely in an OCI Object Storage bucket.
