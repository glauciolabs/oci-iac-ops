# accounts/main.tf

terraform {
  backend "oci" {
    key = "terraform.tfstate"
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

module "oci_network" {
  source          = "../modules/oci-network"
  prefix          = var.prefix
  compartment_id  = var.compartment_ocid
  vcn_cidr        = var.vcn_cidr
  subnet_cidr     = var.subnet_cidr
}

module "oci_ampere_instance" {
  source                  = "../modules/oci-ampere-instance"
  compartment_id          = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.ad_number - 1].name
  subnet_id               = module.oci_network.subnet_id
  image_ocid              = var.image_ocid
  ssh_key                 = var.ssh_key
  instance_count          = var.instance_count
  instance_shape          = var.instance_shape
  instance_memory_gb      = var.instance_memory_gb
  instance_ocpus          = var.instance_ocpus
  instance_prefix         = var.prefix
  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
}

module "shared_volumes" {
  source              = "../modules/oci-shared-volumes"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.ad_number - 1].name
  shared_volumes      = var.shared_volumes_config
}

locals {
  instance_ids = module.oci_ampere_instance.instance_ids
  # Create a flat list of { instance_id, volume_id, volume_key } for each attachment
  volume_attachments = flatten([
    for instance_id in local.instance_ids : [
      for volume_key, volume in module.shared_volumes.volumes : {
        instance_id = instance_id
        volume_id   = volume.id
        volume_key  = volume_key
      }
    ]
  ])
}

resource "oci_core_volume_attachment" "shared_attachment" {
  count = length(local.volume_attachments)

  attachment_type = "iscsi"
  is_shareable    = true
  instance_id     = local.volume_attachments[count.index].instance_id
  volume_id       = local.volume_attachments[count.index].volume_id
  # Use a simple device mapping based on the volume key
  device          = local.volume_attachments[count.index].volume_key == "database_storage" ? "/dev/oracleoci/oraclevdb" : "/dev/oracleoci/oraclevdc"
}
