locals {
  tcp_protocol  = "6"
  all_protocols = "all"
  anywhere      = "0.0.0.0/0"
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = "${var.compartment_ocid}"
}

resource "oci_core_virtual_network" "virtual_network" {
  display_name   = "virtual_network"
  compartment_id = "${var.compartment_ocid}"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "kinetica"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  display_name   = "internet_gateway"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"
}

resource "oci_core_route_table" "route_table" {
  display_name   = "route_table"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internet_gateway.id}"
  }
}

resource "oci_core_security_list" "security_list" {
  display_name   = "security_list"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"

  egress_security_rules = [
    {
      protocol    = "${local.all_protocols}"
      destination = "${local.anywhere}"
    },
  ]

  ingress_security_rules {
    protocol = "${local.tcp_protocol}"
    source   = "${local.anywhere}"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "${local.all_protocols}"
    source   = "10.0.0.0/16"
  }

  ingress_security_rules {
    protocol = "${local.tcp_protocol}"
    source   = "${local.anywhere}"

    tcp_options {
      max = "8080"
      min = "8080"
    }
  }

  ingress_security_rules {
    protocol = "${local.tcp_protocol}"
    source   = "${local.anywhere}"

    tcp_options {
      max = "8088"
      min = "8088"
    }
  }

}

resource "oci_core_subnet" "subnet" {
  display_name        = "subnet"
  compartment_id      = "${var.compartment_ocid}"
  cidr_block          = "10.0.0.0/16"
  vcn_id              = "${oci_core_virtual_network.virtual_network.id}"
  route_table_id      = "${oci_core_route_table.route_table.id}"
  security_list_ids   = ["${oci_core_security_list.security_list.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.virtual_network.default_dhcp_options_id}"
  dns_label           = "kinetica"
}
