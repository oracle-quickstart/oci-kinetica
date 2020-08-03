# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/cloud-partners/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

# Required by the OCI Provider
variable "tenancy_ocid" {
}

variable "compartment_ocid" {
}

variable "region" {
}

# Key used to SSH to OCI instances
variable "ssh_public_key" {
}


# ---------------------------------------------------------------------------------------------------------------------
# Marketplace variables
# ---------------------------------------------------------------------------------------------------------------------

variable "mp_listing_id" {
  default = "ocid1.appcataloglisting.oc1..aaaaaaaalxpgjznatztyqaz2n4krqz5n6s7h5u6kymj4wcxmqmmcsmkyaykq"
}

variable "mp_listing_resource_id" {
  default = "ocid1.image.oc1..aaaaaaaaewd73p7gagjkemzjs6k63bkl4xaeyennh3qv27dvow2h6l4m5zeq"
}

variable "mp_listing_resource_version" {
  default = "1.0"
}

variable "use_marketplace_image" {
  default = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# ---------------------------------------------------------------------------------------------------------------------

variable "license_key" {
  type = string
}

variable "shape" {
  default     = "VM.Standard2.8"
  description = "Instance shape to deploy for each worker."
}

variable "worker_count" {
  default     = "3"
  description = "Number of worker nodes to deploy."
}

variable "ad_number" {
  default     = 0
  description = "Which availability domain to deploy to depending on quota, zero based."
}

# Not used for normal terraform apply, added for ORM deployments.
variable "ad_name" {
  default = ""
}

variable "disk_size" {
  default     = 500
  description = "Size of block volume in GB for data, min 50. If set to 0 volume will not be created/mounted."
}

variable "disk_count" {
  default     = 1
  description = "Number of disks to create for each worker. Multiple disks will create a RAID0 array."
}
