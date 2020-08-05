
resource "oci_core_instance" "worker" {
  display_name        = "kinetica-worker-${count.index}"
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  shape               = var.shape

  source_details {
    source_id   = local.image
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = local.use_existing_network ? var.subnet_id : oci_core_subnet.simple_subnet[0].id
    hostname_label = "kinetica-worker-${count.index}"
    nsg_ids                = [oci_core_network_security_group.simple_nsg.id]
    assign_public_ip       = local.is_public_subnet
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

  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
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
