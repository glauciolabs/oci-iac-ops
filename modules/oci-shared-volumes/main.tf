# modules/oci-shared-volumes/main.tf

resource "oci_core_volume" "shared_volume" {
  for_each = var.shared_volumes

  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = each.value.display_name
  size_in_gbs         = each.value.size_in_gbs
  vpus_per_gb         = 10
}
