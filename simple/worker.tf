locals {
  # Used locally to determine the correct platform image. Shape names always
  # start with either 'VM.'/'BM.' and all GPU shapes have 'GPU' as the next characters
  shape_type = "${lower(substr(var.shape,3,3))}"
}

resource "oci_core_instance" "worker" {
  display_name        = "kinetica-worker-${count.index}"
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.ad_number],"name")}"
  shape               = "${var.shape}"
  subnet_id           = "${oci_core_subnet.subnet.id}"

  source_details {
    source_id   = "${local.shape_type == "gpu" ? var.platform-images["${var.region}-gpu"] : var.platform-images[var.region]}"
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = "${oci_core_subnet.subnet.id}"
    hostname_label = "kinetica-worker-${count.index}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"

    user_data = "${base64encode(join("\n", list(
      "#!/usr/bin/env bash",
      file("../scripts/metadata.sh"),
      file("../scripts/disks.sh"),
      file("../scripts/worker.sh")
    )))}"
  }

  extended_metadata {
    license_key = "${var.license_key}"
    config = "${jsonencode(map(
      "shape", var.shape,
      "disk_count", var.disk_count,
      "disk_size", var.disk_size,
      "worker_count", var.worker_count,
      "license_key", var.license_key
    ))}"
  }

  count = "${var.worker_count}"
}

output "Worker server public IPs" {
  value = "${join(",", oci_core_instance.worker.*.public_ip)}"
}

output "Worker server private IPs" {
  value = "${join(",", oci_core_instance.worker.*.private_ip)}"
}

output "GAdmin URL" {
  value = "http://${oci_core_instance.worker.0.public_ip}:8080"
}

output "Reveal URL" {
  value = "http://${oci_core_instance.worker.0.public_ip}:8088"
}
