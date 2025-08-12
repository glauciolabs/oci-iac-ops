# modules/oci-shared-volumes/outputs.tf

output "volumes" {
  description = "A map of the created shared block volumes."
  value = {
    for key, volume in oci_core_volume.shared_volume : key => volume
  }
}
