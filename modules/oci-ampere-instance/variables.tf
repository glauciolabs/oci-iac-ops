# modules/oci-ampere-instance/variables.tf

variable "compartment_id" {
  type        = string
  description = "Compartment OCID"
}

variable "availability_domain" {
  type        = string
  description = "Availability domain name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet OCID"
}

variable "image_ocid" {
  type        = string
  description = "Image OCID"
}

variable "ssh_key" {
  type        = string
  description = "SSH public key"
}

variable "instance_count" {
  type        = number
  description = "Number of instances"
}

variable "instance_shape" {
  type        = string
  description = "Instance shape"
}

variable "instance_memory_gb" {
  type        = number
  description = "Memory in GB for each instance"
}

variable "instance_ocpus" {
  type        = number
  description = "Number of OCPUs for each instance"
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size in GB; null for image default"
  default     = null
}

variable "instance_prefix" {
  type        = string
  description = "Instance name prefix"
}