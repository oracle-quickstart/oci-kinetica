locals {
  # Used locally to determine the correct platform image. Shape names always
  # start with either 'VM.'/'BM.' and all GPU shapes have 'GPU' as the next characters
  shape_type = lower(substr(var.shape, 3, 3))

  # If ad_number is non-negative use it for AD lookup, else use ad_name.
  # Allows for use of ad_number in TF deploys, and ad_name in ORM.
  # Use of max() prevents out of index lookup call.
  ad = var.ad_number >= 0 ? data.oci_identity_availability_domains.availability_domains.availability_domains[max(0, var.ad_number)]["name"] : var.ad_name

  image          = var.mp_listing_resource_id
}

resource "oci_core_instance" "worker" {
  display_name        = "kinetica-worker-${count.index}"
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  shape               = var.shape

  source_details {
    source_id   = local.image
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.subnet.id
    hostname_label = "kinetica-worker-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          file("./scripts/metadata.sh"),
          file("./scripts/disks.sh"),
          file("./scripts/worker.sh"),
        ],
      ),
    )
  }

  extended_metadata = {
    license_key = var.license_key
    config = jsonencode(
      {
        "shape"        = var.shape
        "disk_count"   = var.disk_count
        "disk_size"    = var.disk_size
        "worker_count" = var.worker_count
        "license_key"  = var.license_key
      },
    )
  }

  count = var.worker_count
}

output "worker_public_ips" {
  value = join(",", oci_core_instance.worker.*.public_ip)
}

output "worker_private_ips" {
  value = join(",", oci_core_instance.worker.*.private_ip)
}

output "gadmin_url" {
  value = "http://${oci_core_instance.worker[0].public_ip}:8080"
}

output "reveal_url" {
  value = "http://${oci_core_instance.worker[0].public_ip}:8088"
}
