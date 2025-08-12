<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# poderia ajustar o meu readme.md?

# Terraform OCI Multi-Account Infrastructure

A comprehensive Terraform solution for deploying Oracle Cloud Infrastructure (OCI) resources across multiple accounts using GitHub Actions automation, modular architecture, native OCI backend state management, and flexible instance configuration.

## 🏗️ Architecture Overview

This solution provides:

- **Multi-Account Support**: Deploy infrastructure to different OCI accounts using JSON configuration
- **Modular Design**: Reusable Terraform modules for networking and compute resources
- **GitHub Actions Integration**: Automated deployment workflows with secure secret management
- **Native OCI Backend**: Remote state storage using OCI Object Storage
- **Flexible Instance Configuration**: Dynamic instance count, shapes, CPU, and memory per account
- **Cost Optimization**: Different resource allocations for production, development, and testing environments


## 📁 Project Structure

```


.
├── accounts/
│   ├── main.tf                     \# Main Terraform configuration
│   └── variables.tf                \# Variable definitions
├── modules/
│   ├── oci-network/                \# VCN, subnets, gateways, security
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── oci-ampere-instance/        \# Compute instances with flexible config
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── oci-terraform-backend/      \# Backend bucket configuration
│       ├── main.tf
│       └── variables.tf
├── scripts/
│   ├── run.sh                      \# Main execution script
│   └── install-terraform.sh       \# Terraform installation utility
└── .github/
└── workflows/
└── terraform.yml           \# GitHub Actions workflow


```


## 🔧 Prerequisites \& Initial Setup

### **1. Oracle Cloud Infrastructure Account**

- Active OCI account with administrator access
- Access to OCI Console at https://cloud.oracle.com


### **2. Required OCI Resources Setup**

#### **Create Object Storage Bucket for Terraform State**

1. **Navigate to Object Storage**:
   - Login to OCI Console
   - Go to **Storage → Buckets**
   - Select your target compartment
2. **Create New Bucket**:
```


Bucket Name: terraform-state-[environment]
Storage Tier: Standard
Encryption: Oracle-managed keys
Emit Object Events: Disabled
Object Versioning: Enabled (recommended)


```

3. **Copy Namespace** (Important for state recovery):

- Click on your bucket name
- Copy **namespace** information


#### **Create API Key and Get Account Details**

1. **Generate API Key Pair**:
```
Link: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm
```

3. **Copy Configuration Details**:
After downloading or adding the API key, OCI will display a configuration snippet like:
```


[DEFAULT]
user=ocid1.user.oc1..aaaaaaaabbbbbbbccccccddddddd
fingerprint=12:34:56:78:9a:bc:de:f0:12:34:56:78:9a:bc:de:f0
tenancy=ocid1.tenancy.oc1..aaaaaaaabbbbbbbccccccddddddd
region=us-ashburn-1
key_file=~/.oci/oci_api_key.pem


```

4. **Get Additional Required Information**:

- **Compartment OCID**: Go to **Identity \& Security → Compartments** → Click compartment name → Copy OCID
- **Availability Domain**: Go to **Governance → Limits, Quotas and Usage** → Select service → Note available ADs
- **Region**: Your current region (visible in top-right corner of console)


### **3. Local Development Environment**

- `jq` for JSON processing: `sudo apt install jq`
- `curl` for downloads: `sudo apt install curl`
- Git for version control
- SSH key pair for instance access


## ⚙️ Configuration

### **1. Account Configuration JSON**

Create a JSON file with your account details including flexible instance configuration:

```


{
"1": {
"account_name": "production",
"availability_domain": "sa-saopaulo-1-AD-1",
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
"private_key": "-----BEGIN PRIVATE KEY-----\n[YOUR_PRIVATE_KEY_CONTENT]\n-----END PRIVATE KEY-----",
"instance_count": 3,
"instance_shape": "VM.Standard.A1.Flex",
"instance_memory_gb": 24,
"instance_ocpus": 4
},
"2": {
"account_name": "development",
"availability_domain": "sa-saopaulo-1-AD-1",
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
"private_key": "-----BEGIN PRIVATE KEY-----\n[YOUR_DEV_PRIVATE_KEY_CONTENT]\n-----END PRIVATE KEY-----",
"instance_count": 1,
"instance_shape": "VM.Standard.A1.Flex",
"instance_memory_gb": 6,
"instance_ocpus": 1
}
}


```


### **2. How to Get Configuration Values**

| Field | How to Obtain |
| :-- | :-- |
| `account_name` | Your environment name (custom) |
| `availability_domain` | OCI Console → Governance → Limits, Quotas and Usage |
| `compartment_ocid` | Identity \& Security → Compartments → Copy OCID |
| `fingerprint` | Generated when adding API key to user |
| `image_ocid` | Compute → Custom Images or use Oracle-provided images |
| `namespace` | Administration → Tenancy Details → Object Storage Namespace |
| `region` | Your OCI region (e.g., sa-saopaulo-1, us-ashburn-1) |
| `ssh_public_key` | Your SSH public key content (`cat ~/.ssh/id_rsa.pub`) |
| `tenancy_ocid` | Administration → Tenancy Details → OCID |
| `tf_state_bucket_name` | Name of bucket created for Terraform state |
| `user_ocid` | Identity \& Security → Users → Your User → OCID |
| `private_key` | Content of your OCI API private key file |

### **3. GitHub Secrets Setup**

1. **Add private key to JSON configuration**:
```


jq --arg private_key "\$(cat ~/.oci/oci_api_key.pem)" \
'.["1"].private_key = \$private_key' \
config.json > updated_config.json


```

2. **Encode JSON as Base64**:
```


cat updated_config.json | base64 -w 0 > github_secret.txt


```

3. **Add to GitHub Repository**:
   - Go to **Settings → Secrets and variables → Actions**
   - Create **New repository secret**
   - Name: `OCI_ACCOUNTS_JSON`
   - Value: Contents of `github_secret.txt`

## 🚀 Usage

### **GitHub Actions Deployment**

1. Navigate to **Actions** tab in your GitHub repository
2. Select **Terraform OCI Multi-Account** workflow
3. Click **Run workflow**
4. Configure parameters:
   - **Account Number**: Select account (1, 2, 3, etc.)
   - **Operation**: Choose `plan`, `apply`, or `destroy`
5. Monitor execution in the Actions log

### **Local Development**

1. **Install Terraform** (if not installed):
```


sudo bash scripts/install-terraform.sh


```

2. **Run Terraform operations**:
```


# Navigate to project directory


cd /path/to/project


# Execute plan operation


bash scripts/run.sh config.json 1 plan \$(pwd)/accounts


# Execute apply operation


bash scripts/run.sh config.json 1 apply \$(pwd)/accounts


```


## 🔐 Security Features

- **Private key encryption**: Keys are stored encrypted in GitHub Secrets
- **Temporary file cleanup**: Sensitive files are automatically removed after execution
- **Secure authentication**: Uses OCI API key authentication
- **State encryption**: Remote state stored securely in OCI Object Storage
- **Access control**: Configurable security groups and network ACLs
- **State versioning**: Bucket versioning enabled for state recovery


## 🏛️ Infrastructure Details

### **Network Configuration**

- **VCN**: Virtual Cloud Network with custom CIDR
- **Public Subnet**: Internet-accessible subnet for instances
- **Internet Gateway**: Provides internet access
- **Route Tables**: Routes traffic to/from internet
- **Security Lists**: Allows SSH (22), HTTP (80), HTTPS (443)


### **Flexible Compute Configuration**

- **Dynamic Instance Count**: 1-N instances per environment
- **Multi-Shape Support**:
  - `VM.Standard.A1.Flex` (ARM-based Ampere)
  - `VM.Standard.E4.Flex` (AMD-based)
  - `VM.Standard3.Flex` (Intel-based)
- **Configurable Resources**: Memory (1-64 GB) and vCPUs (1-24) per instance
- **Environment-Specific Sizing**: Different configurations per account
- **OS**: Configurable via image OCID
- **Access**: SSH key-based authentication


### **Example Configurations**

- **Production (Account 1)**: 3x VM.Standard.A1.Flex (4 vCPU, 24GB RAM each)
- **Development (Account 2)**: 1x VM.Standard.A1.Flex (1 vCPU, 6GB RAM)
- **Staging (Account 3)**: 2x VM.Standard.E4.Flex (2 vCPU, 16GB RAM each)


## 🔄 Backend State Management

The solution uses OCI's native Terraform backend for remote state storage:

- **State Location**: OCI Object Storage bucket
- **Encryption**: Server-side encryption enabled
- **Locking**: Prevents concurrent modifications
- **Versioning**: Maintains state history (recommended)
- **Access Control**: Secure API-based authentication


## 🛠️ Customization

### **Adding New Accounts**

Add additional account configurations to your JSON file with unique keys:

```


{
"1": { /* production config */ },
"2": { /* development config */ },
"3": { /* staging config */ },
"4": { /* testing config */ }
}


```


### **Instance Configuration Options**

Configure instances per account with these parameters:

- **`instance_count`**: Number of instances (1-50)
- **`instance_shape`**: OCI instance shape
- **`instance_memory_gb`**: Memory allocation (1-64 GB for Flex shapes)
- **`instance_ocpus`**: vCPU allocation (1-24 for Flex shapes)


### **Supported Instance Shapes**

- **ARM Ampere**: `VM.Standard.A1.Flex`
- **AMD EPYC**: `VM.Standard.E3.Flex`, `VM.Standard.E4.Flex`
- **Intel Xeon**: `VM.Standard3.Flex`, `VM.Standard.E2.1.Micro`


### **Network Customization**

Edit `modules/oci-network/main.tf`:

- Modify CIDR blocks
- Add additional subnets
- Configure custom security rules
- Add load balancers or NAT gateways


## 🎯 Cost Optimization Examples

### **Development Environment**

```


"instance_count": 1,
"instance_shape": "VM.Standard.A1.Flex",
"instance_memory_gb": 6,
"instance_ocpus": 1


```

*Estimated cost: ~\$5-10/month*

### **Production Environment**

```


"instance_count": 3,
"instance_shape": "VM.Standard.A1.Flex",
"instance_memory_gb": 24,
"instance_ocpus": 4


```

*Estimated cost: ~\$60-90/month*

### **Load Testing Environment**

```


"instance_count": 5,
"instance_shape": "VM.Standard.E4.Flex",
"instance_memory_gb": 32,
"instance_ocpus": 8


```

*Estimated cost: ~\$200-300/month*

## 📊 Monitoring \& Troubleshooting

### **GitHub Actions Logs**

Monitor deployment progress through GitHub Actions interface:

- Real-time execution logs
- Resource creation status
- Error debugging information
- Instance configuration validation


### **Common Issues**

1. **Provider Configuration Errors**: Ensure `required_providers` block is removed from `main.tf`
2. **Authentication Failures**: Verify API key format and GitHub secret configuration
3. **Resource Limits**: Check OCI service limits and quotas for chosen shapes
4. **Network Connectivity**: Verify VCN and subnet configurations
5. **Shape Availability**: Verify chosen instance shapes are available in selected regions
6. **Backend Access**: Ensure bucket exists and user has proper permissions

## 📋 Requirements

- **Terraform**: >= 1.12.0 (for native OCI backend support)
- **OCI Provider**: Latest version (automatically installed)
- **System Dependencies**: `curl`, `unzip`, `jq`, `base64`
- **OCI Permissions**: Full access to Compute, Networking, and Object Storage services
- **OCI Quotas**: Sufficient service limits for chosen instance shapes and counts


## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Additional Resources

- [Oracle Cloud Infrastructure Documentation](https://docs.oracle.com/en-us/iaas/)
- [Terraform OCI Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Object Storage Bucket Setup](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/managingbuckets.htm)
- [OCI API Key Setup Guide](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OCI Ampere Instance Documentation](https://docs.oracle.com/en-us/iaas/Content/Compute/References/arm-based-instances.htm)
- [OCI Instance Shapes Documentation](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)
- [OCI Always Free Tier](https://www.oracle.com/cloud/free/)

---

**Note**: This solution is designed for production use with proper security practices. Always review and test configurations in development environments before applying to production resources. The flexible instance configuration allows for cost-effective scaling across different environments while maintaining infrastructure consistency.

```

Of course. Based on the latest architecture with modular and shared block volumes, I've adjusted your `README.md` to be accurate, clear, and comprehensive.

Here is the updated version, ready to be copied and pasted.

***

# Terraform OCI Multi-Account Infrastructure

A comprehensive Terraform solution for deploying Oracle Cloud Infrastructure (OCI) resources across multiple accounts. This project features GitHub Actions automation, a modular architecture for networking, compute, and shared storage, native OCI backend state management, and flexible, per-account instance configuration.

## 🏗️ Architecture Overview

This solution provides:
- **Multi-Account Support**: Deploy infrastructure to different OCI accounts using a single JSON configuration file.
- **Modular Design**: Reusable Terraform modules for networking, compute instances, and shared block volumes.
- **Shared Storage**: A dedicated module for creating block volumes that can be attached in shared mode across multiple instances.
- **GitHub Actions Integration**: Automated deployment workflows (`plan`, `apply`, `destroy`) with secure secret management.
- **Native OCI Backend**: Remote state storage using an OCI Object Storage bucket for reliability and team collaboration.
- **Flexible Instance Configuration**: Dynamically configure instance count, shapes, CPU, and memory for each account.
- **Dynamic Availability Domain**: Select the Availability Domain (AD) using a simple number (1, 2, or 3) instead of hardcoding names.

## 📁 Project Structure

```

.
├── accounts/
│   ├── main.tf                  \# Main Terraform configuration (root module)
│   └── variables.tf             \# Variable definitions for the root module
├── modules/
│   ├── oci-ampere-instance/     \# Creates flexible compute instances
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── oci-network/             \# Manages VCN, subnets, gateways, and security
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── oci-shared-volumes/      \# New: Creates shared block volumes
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── oci-terraform-backend/   \# Configures the backend bucket (optional)
│       ├── main.tf
│       └── variables.tf
├── scripts/
│   ├── run.sh                   \# Main execution script for local and CI/CD
│   └── install-terraform.sh     \# Utility for installing Terraform
└── .github/
└── workflows/
└── terraform.yml        \# GitHub Actions workflow definition

```

## 🔧 Prerequisites & Initial Setup

### 1. Oracle Cloud Infrastructure Account
- An active OCI account with administrator-level permissions.
- Access to the OCI Console at [cloud.oracle.com](https://cloud.oracle.com).

### 2. Required OCI Resources

#### Create Object Storage Bucket for Terraform State
1.  **Navigate to Object Storage**: In the OCI Console, go to **Storage > Buckets** and select your target compartment.
2.  **Create New Bucket** with the following settings:
    *   **Bucket Name**: `terraform-state-[environment]` (e.g., `terraform-state-prod`)
    *   **Storage Tier**: `Standard`
    *   **Encryption**: `Oracle-managed keys`
    *   **Object Versioning**: `Enabled` (highly recommended for state recovery)
3.  **Copy Namespace**: After creating the bucket, go to your tenancy details page (**Administration > Tenancy Details**) and copy the **Object Storage Namespace**.

#### Create API Key and Get Account Details
1.  **Generate API Key Pair**: Follow the official guide to [generate an API signing key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm).
2.  **Add Public Key to User**: Add the generated public key to your user profile in the OCI Console.
3.  **Copy Configuration Snippet**: After adding the key, OCI will display a configuration snippet. Copy the following values from it:
    *   `user` (User OCID)
    *   `fingerprint`
    *   `tenancy` (Tenancy OCID)
    *   `region`
4.  **Get Compartment OCID**: Go to **Identity & Security > Compartments**, click your target compartment, and copy its OCID.

### 3. Local Development Environment
- **jq**: `sudo apt install jq`
- **curl** & **unzip**: `sudo apt install curl unzip`
- **Git**: For version control.
- **SSH Key Pair**: For accessing the compute instances.

## ⚙️ Configuration

### 1. Account Configuration JSON
Create a JSON file (e.g., `accounts.json`) with your account details. This file is the single source of truth for all environments.

```json
{
  "1": {
    "account_name": "production",
    "ad_number": 1,
    "compartment_ocid": "ocid1.compartment.oc1..aaaa...",
    "fingerprint": "12:34:56:78:9a:bc:de:f0:...",
    "image_ocid": "ocid1.image.oc1.sa-saopaulo-1.aaaa...",
    "namespace": "your-tenancy-namespace",
    "prefix": "prod",
    "region": "sa-saopaulo-1",
    "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAA...",
    "subnet_cidr": "10.0.1.0/24",
    "tenancy_ocid": "ocid1.tenancy.oc1..bbbb...",
    "tf_state_bucket_name": "terraform-state-prod",
    "user_ocid": "ocid1.user.oc1..cccc...",
    "vcn_cidr": "10.0.0.0/16",
    "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----",
    "instance_count": 2,
    "instance_shape": "VM.Standard.A1.Flex",
    "instance_memory_gb": 12,
    "instance_ocpus": 2
  },
  "2": {
    "account_name": "development",
    "ad_number": 1,
    "compartment_ocid": "ocid1.compartment.oc1..dddd...",
    "fingerprint": "98:76:54:32:10:fe:dc:ba:...",
    "image_ocid": "ocid1.image.oc1.sa-saopaulo-1.aaaa...",
    "namespace": "your-tenancy-namespace",
    "prefix": "dev",
    "region": "sa-saopaulo-1",
    "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAA...",
    "subnet_cidr": "10.1.1.0/24",
    "tenancy_ocid": "ocid1.tenancy.oc1..bbbb...",
    "tf_state_bucket_name": "terraform-state-dev",
    "user_ocid": "ocid1.user.oc1..eeee...",
    "vcn_cidr": "10.1.0.0/16",
    "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----",
    "instance_count": 1,
    "instance_shape": "VM.Standard.E2.1.Micro",
    "instance_memory_gb": 1,
    "instance_ocpus": 1
  }
}
```


### 2. GitHub Secrets Setup

1. **Add Private Key to JSON**: Use `jq` to safely embed your private key file's content into the JSON.

```bash
jq --arg private_key "$(cat ~/.oci/oci_api_key.pem)" '.["1"].private_key = $private_key' accounts.json > temp.json && mv temp.json accounts.json
```

2. **Encode JSON as Base64**:

```bash
cat accounts.json | base64 -w 0 > github_secret.txt
```

3. **Add to GitHub Repository**:
    * Go to **Settings > Secrets and variables > Actions**.
    * Create a **New repository secret**.
    * **Name**: `OCI_ACCOUNTS_JSON`
    * **Value**: Paste the entire content of `github_secret.txt`.

## 🚀 Usage

### GitHub Actions Deployment

1. Navigate to the **Actions** tab in your GitHub repository.
2. Select the **Terraform OCI Multi-Account** workflow.
3. Click **Run workflow**.
4. Configure the parameters:
    * **Account Number**: Select the target account (e.g., `1` for production).
    * **Operation**: Choose `plan`, `apply`, or `destroy`.
5. Monitor the execution in the Actions log.

### Local Development

1. **Install Terraform** (if not already present):

```bash
sudo bash scripts/install-terraform.sh
```

2. **Run Terraform operations** from the project root:

```bash
# Plan for account 1
bash scripts/run.sh accounts.json 1 plan $(pwd)/accounts

# Apply for account 2
bash scripts/run.sh accounts.json 2 apply $(pwd)/accounts
```


## 🏛️ Infrastructure Details

### Network Configuration

- **VCN**: A Virtual Cloud Network with a custom CIDR block.
- **Public Subnet**: An internet-accessible subnet for instances.
- **Internet Gateway**: Provides internet access for the VCN.
- **Route Tables**: Manages traffic routing to and from the internet.
- **Security Lists**: A default security list allowing SSH (22), HTTP (80), and HTTPS (443) ingress traffic.


### Flexible Compute Configuration

- **Dynamic Instance Count**: 1-N instances per environment.
- **Multi-Shape Support**: Compatible with ARM (`VM.Standard.A1.Flex`), AMD (`VM.Standard.E4.Flex`), and Intel (`VM.Standard3.Flex`) shapes.
- **Configurable Resources**: Flexibly allocate memory and OCPUs for each instance.
- **OS**: Configurable via the `image_ocid`.


### Shared Storage Configuration

- **Modular Volumes**: A dedicated `oci-shared-volumes` module creates block volumes.
- **Centralized Definition**: Volume sizes and names are defined in `accounts/variables.tf`.
- **Shared Attachments**: Volumes are automatically attached to all created instances in `is_shareable = true` mode, ready for use with a clustered filesystem like OCFS2.


## 🛠️ Customization

### Adding New Accounts

Add new account objects to your `accounts.json` file with unique numerical keys (`"3"`, `"4"`, etc.).

### Customizing Shared Volumes

Modify the `shared_volumes_config` variable in `accounts/variables.tf` to add, remove, or resize the shared block volumes.

```hcl
variable "shared_volumes_config" {
  type = map(object({
    display_name = string
    size_in_gbs  = number
  }))
  default = {
    "database_storage" = {
      display_name = "database-storage"
      size_in_gbs  = 100 // Changed size
    },
    "app_logs" = { // Added a new volume
      display_name = "app-logs"
      size_in_gbs  = 75
    }
  }
}
```


### Network Customization

Edit `modules/oci-network/main.tf` to:

- Add or remove subnets (e.g., private subnets).
- Configure custom ingress/egress rules in the `oci_core_security_list` resource.
- Add other resources like Load Balancers or NAT Gateways.


## 🤝 Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-new-feature`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/my-new-feature`).
5. Open a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

