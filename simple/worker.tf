resource "oci_core_instance" "worker" {
  display_name        = "kinetica-worker-${count.index}"
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[0],"name")}"
  shape               = "${var.worker["shape"]}"
  subnet_id           = "${oci_core_subnet.subnet.id}"

  source_details {
    source_id   = "${var.images[var.region]}"
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
      "password=${var.worker["password"]}",
      file("../scripts/worker.sh")
    )))}"
  }

  freeform_tags = {
    "Quickstart" = "{\"Deployment\":\"TF\", \"Publisher\":\"Kinetica\", \"Offer\":\"kinetica\",\"Licence\":\"byol\"}"
  }

  count = "${var.worker["worker_count"]}"
}

output "Worker server public IPs" {
  value = "${join(",", oci_core_instance.worker.*.public_ip)}"
}

output "Worker server private IPs" {
  value = "${join(",", oci_core_instance.worker.*.private_ip)}"
}
