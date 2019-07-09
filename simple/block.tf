
resource "oci_core_volume" "WorkerVolume" {
  count               = "${var.worker["worker_count"] * var.worker["disk_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.worker["ad_number"]],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "worker-${count.index % var.worker["worker_count"]}-volume${floor(count.index / var.worker["worker_count"])}"
  size_in_gbs         = "${var.worker["disk_size"]}"

}

resource "oci_core_volume_attachment" "WorkerAttachment" {
  count           = "${var.worker["worker_count"] * var.worker["disk_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.WorkerVolume.*.id[count.index]}"
}
