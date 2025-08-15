# accounts/variables.tf

variable "compartment_ocid" {
  type        = string
  description = "OCI compartment OCID"
}

variable "image_ocid" {
  type        = string
  description = "Image OCID"
}

variable "ssh_key" {
  type        = string
  description = "SSH public key"
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID"
}

variable "user_ocid" {
  type        = string
  description = "OCI user OCID"
}

variable "fingerprint" {
  type        = string
  description = "API key fingerprint"
}

variable "private_key_path" {
  type        = string
  description = "Path to private key"
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 2
}

variable "instance_shape" {
  type        = string
  description = "Instance shape"
  default     = "VM.Standard.A1.Flex"
}

variable "instance_memory_gb" {
  type        = number
  description = "Memory in GB for each instance"
  default     = 12
}

variable "instance_ocpus" {
  type        = number
  description = "Number of OCPUs for each instance"
  default     = 2
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size in GB; null to use image default"
  default     = null
}

variable "ad_number" {
  type        = number
  description = "Availability domain number (1, 2, or 3)"
  default     = 1
  nullable    = false
}

variable "vcn_cidr" {
  type        = string
  description = "VCN CIDR block"
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR block"
  default     = "10.10.1.0/24"
}

variable "shared_volumes_config" {
  description = "Configuration for the shared block volumes."
  type = map(object({
    display_name = string
    size_in_gbs  = number
  }))
  default = {
    "database_storage" = {
      display_name = "database-storage"
      size_in_gbs  = 50
    },
    "file_storage" = {
      display_name = "file-storage"
      size_in_gbs  = 56
    }
  }
}
