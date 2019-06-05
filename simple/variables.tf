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
    shape      = "VM.GPU3.1"
    worker_count = 1
    # Which availability domain to deploy to depending on quota, zero based
    ad_number = 2
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
    ap-seoul-1 =	"ocid1.image.oc1.ap-seoul-1.aaaaaaaaekhzdpa2oibo4cgh4whp54gv3sh5y277k7ykqvzcmm7f7xuujf7q"
    ap-tokyo-1 =	"ocid1.image.oc1.ap-tokyo-1.aaaaaaaaqgxuylamck3u4z43lqhcjmk63mgmwle2kuxn7urcvs3zernbmidq"
    ca-toronto-1 =	"ocid1.image.oc1.ca-toronto-1.aaaaaaaaao3hzbyh3nlcif672hnkarlbmaqk47woffzcgrlgt6xg5iffoy3a"
    eu-frankfurt-1 = 	"ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeaa5m5ioxbrb3dstql2kzcuspidcvimey2lswpn5vasyxvoqpvxa"
    uk-london-1 =	"ocid1.image.oc1.uk-london-1.aaaaaaaapsbpob5y3hodz2l2izyhluolrapfm2p66rzv4a2seqcehjjdgteq"
    us-ashburn-1 =	"ocid1.image.oc1.iad.aaaaaaaaklskal5ezaay6imvl6iwzcelke5uavkt5smpla7o45g5xmcmv2da"
    us-phoenix-1 =	"ocid1.image.oc1.phx.aaaaaaaal4eq2dujwuefgqxoz76jlxxtebyy6rtql7lopvkbp4z5j3ydut3q"
  }
}
