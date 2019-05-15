# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/cloud-partners/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

# Required by the OCI Provider
variable "tenancy_ocid" {}

variable "compartment_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

# Key used to SSH to OCI VMs
variable "ssh_public_key" {}

variable "ssh_private_key" {}

# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# The defaults here will give you a cluster.  You can also modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "license_key" {
  type = "string"
  default = "RRUMDiqmYPph-F44W7KTppxH5-dd8aJF1LwpdH-m9rsHJWRJ0bo-wZcHIJgwrp8bgxVyTGkaZlTJzxCRv7VR"
}

variable "worker" {
  type = "map"

  default = {
    shape      = "BM.GPU2.2"
    worker_count = 1
    # Which availability domain to deploy to depending on quota, zero based
    ad_number = 1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Network variables
# ---------------------------------------------------------------------------------------------------------------------

variable "vcn_display_name" {
  default = "testVCN"
}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

# GPU platform images
#
# https://docs.cloud.oracle.com/iaas/images/image/0693e672-c5b9-43ce-821e-dfd918366be9/
# Oracle-Linux-7.6-Gen2-GPU-2019.03.22-1

variable "images" {
  type = "map"

  default = {
    ca-toronto-1   = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa2qu5d42l6wubijavqic26kspjyvi6kn25oiop4di633kcd6e4oeq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaafn5eqdsiraw5rhxfqbf7hizx5dhur4ffmvvpjtx7pew7nqdiux5q"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaa4ra77q7sgfgtknxaeef34z2ezjqt6onv6akifberbibfwhpjddna"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaamg5ew5ymoilp3r3pzgo4pcoajicqavjv7q5bnyd4tibggcwupula"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaiza335ab5niqcjscm5yithovegaxzsipmchrujez7gk4ij5pjqvq"
  }
}
