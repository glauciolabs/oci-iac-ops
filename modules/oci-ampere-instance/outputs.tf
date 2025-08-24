# modules/oci-ampere-instance/outputs.tf

output "instances_details" {
  value = [
    for i in oci_core_instance.ampere_instance : {
      id           = i.id
      display_name = i.display_name
      public_ip    = i.public_ip
      private_ip   = i.private_ip
      shape        = i.shape
      region       = i.region
    }
  ]
}

output "instance_ids" {
  description = "List of Instance OCIDs."
  value       = [for i in oci_core_instance.ampere_instance : i.id]
}

output "instance_ids_map" {
  description = "A map of Instance OCIDs, keyed by the instance index."
  value = {
    for index, instance in oci_core_instance.ampere_instance : tostring(index) => instance.id
  }
}