# modules/oci-shared-volumes/variables.tf

variable "compartment_id" {
  type        = string
  description = "The OCID of the compartment to create the volumes in."
}

variable "availability_domain" {
  type        = string
  description = "The Availability Domain to create the volumes in."
}

variable "shared_volumes" {
  description = "A map of shared block volumes to create."
  type = map(object({
    display_name = string
    size_in_gbs  = number
  }))
  default = {}
}
