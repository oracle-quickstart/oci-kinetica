resource "oci_core_network_security_group" "simple_nsg" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_id : oci_core_vcn.simple.0.id

  #Optional
  display_name = var.nsg_display_name

}

# Allow Egress traffic to all networks
resource "oci_core_network_security_group_security_rule" "simple_rule_egress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id

  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"

}

# Allow SSH (TCP port 22) Ingress traffic from any network
resource "oci_core_network_security_group_security_rule" "simple_rule_ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.nsg_source_cidr
  stateless                 = false
  description               = "SSH"


  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Allow ingress for GAdmin
resource "oci_core_network_security_group_security_rule" "gadmin_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.nsg_source_cidr
  stateless                 = false
  description               = "GAdmin access"

  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
}

# Allow ingress for Reveal
resource "oci_core_network_security_group_security_rule" "reveal_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.nsg_source_cidr
  stateless                 = false
  description               = "Reveal access"

  tcp_options {
    destination_port_range {
      min = 8088
      max = 8088
    }
  }
}

# Allow ingress for AAW
resource "oci_core_network_security_group_security_rule" "aaw_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.nsg_source_cidr
  stateless                 = false
  description               = "AAW access"

  tcp_options {
    destination_port_range {
      min = 8070
      max = 8070
    }
  }
}

# Allow ingress for AAW API
resource "oci_core_network_security_group_security_rule" "aaw_api_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.nsg_source_cidr
  stateless                 = false
  description               = "AAW API access"

  tcp_options {
    destination_port_range {
      min = 8070
      max = 8070
    }
  }
}

# Allow ANY Ingress traffic from within simple vcn
resource "oci_core_network_security_group_security_rule" "simple_rule_all_simple_vcn_ingress" {
  network_security_group_id = oci_core_network_security_group.simple_nsg.id
  protocol                  = "all"
  direction                 = "INGRESS"
  source                    = var.vcn_cidr_block
  stateless                 = false
}
