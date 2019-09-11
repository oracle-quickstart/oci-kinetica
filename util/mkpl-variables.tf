# ---------------------------------------------------------------------------------------------------------------------
# Marketplace variables
# ---------------------------------------------------------------------------------------------------------------------

variable "mp_listing_id" {
  default = ""
}
variable "mp_listing_resource_id" {
  default = ""
}
variable "mp_listing_resource_version" {
 default = ""
}

variable "use_marketplace_image" {
  default = true
}

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {}

# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# ---------------------------------------------------------------------------------------------------------------------

variable "license_key" {
  type = "string"
}

variable "shape" {
  default = "VM.GPU3.1"
  description = "Instance shape to deploy for each worker."
}

variable "worker_count" {
  default = "3"
  description = "Number of worker nodes to deploy."
}

variable "ad_number" {
  default = 2
  description = "Which availability domain to deploy to depending on quota, zero based."
}

variable "disk_size" {
  default = 500
  description = "Size of block volume in GB for data, min 50. If set to 0 volume will not be created/mounted."
}

variable "disk_count" {
  default = 1
  description = "Number of disks to create for each worker. Multiple disks will create a RAID0 array."
}



# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------


# Not used for normal terraform apply, added for ORM deployments.
variable "ad_name" {
  default = ""
}

# Variable not read in a mkpl deploy.

# Both GPU and non-GPU platform images
#
# https://docs.cloud.oracle.com/iaas/images/image/85e2ad5a-3979-4ed2-8d99-9a10d79fa814/
# Oracle-Linux-7.6-Gen2-GPU-2019.05.28-0
# https://docs.cloud.oracle.com/iaas/images/image/6180a2cb-be6c-4c78-a69f-38f2714e6b3d/
# Oracle-Linux-7.6-2019.05.28-0

variable "platform-images" {
  type = "map"

  default = {
    ap-seoul-1-gpu =	"ocid1.image.oc1.ap-seoul-1.aaaaaaaaekhzdpa2oibo4cgh4whp54gv3sh5y277k7ykqvzcmm7f7xuujf7q"
    ap-tokyo-1-gpu =	"ocid1.image.oc1.ap-tokyo-1.aaaaaaaaqgxuylamck3u4z43lqhcjmk63mgmwle2kuxn7urcvs3zernbmidq"
    ca-toronto-1-gpu =	"ocid1.image.oc1.ca-toronto-1.aaaaaaaaao3hzbyh3nlcif672hnkarlbmaqk47woffzcgrlgt6xg5iffoy3a"
    eu-frankfurt-1-gpu = 	"ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeaa5m5ioxbrb3dstql2kzcuspidcvimey2lswpn5vasyxvoqpvxa"
    uk-london-1-gpu =	"ocid1.image.oc1.uk-london-1.aaaaaaaapsbpob5y3hodz2l2izyhluolrapfm2p66rzv4a2seqcehjjdgteq"
    us-ashburn-1-gpu =	"ocid1.image.oc1.iad.aaaaaaaaklskal5ezaay6imvl6iwzcelke5uavkt5smpla7o45g5xmcmv2da"
    us-phoenix-1-gpu =	"ocid1.image.oc1.phx.aaaaaaaal4eq2dujwuefgqxoz76jlxxtebyy6rtql7lopvkbp4z5j3ydut3q"
    ap-seoul-1 =	"ocid1.image.oc1.ap-seoul-1.aaaaaaaa6mmih5n72yviujadzfkzthjwyc3h5uvaeejc3kpalhyakk6tfejq"
    ap-tokyo-1 =	"ocid1.image.oc1.ap-tokyo-1.aaaaaaaayxjigcwqiqjncbkm7yxppjqfzsjnbvtjsemrvnwrtpwynausossa"
    ca-toronto-1 =	"ocid1.image.oc1.ca-toronto-1.aaaaaaaabmpm76byqi5nisxblvh4gtfvfxbnyo4vmoqfvpldggellgrv4eiq"
    eu-frankfurt-1 =	"ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaijslwo4cd3xhcledgwglqwjem3te4q3szekfm37hoo3wf2tm6u5a"
    uk-london-1 =	"ocid1.image.oc1.uk-london-1.aaaaaaaa66i5ug2lc6ywq6j2y4e535vgzsgb7pwn6blv2bw5a2wb2gbo5wfa"
    us-ashburn-1 =	"ocid1.image.oc1.iad.aaaaaaaaj6pcmnh6y3hdi3ibyxhhflvp3mj2qad4nspojrnxc6pzgn2w3k5q"
    us-phoenix-1 =	"ocid1.image.oc1.phx.aaaaaaaa2wadtmv6j6zboncfobau7fracahvweue6dqipmcd5yj6s54f3wpq"
  }
}
