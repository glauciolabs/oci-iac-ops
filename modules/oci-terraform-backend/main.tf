#modules/oci-terraform-backend/main.tf

resource "oci_objectstorage_bucket" "tfstate_bucket" {
  compartment_id = var.compartment_id
  name = var.bucket_name
  namespace      = var.namespace
  access_type    = "NoPublicAccess"
}