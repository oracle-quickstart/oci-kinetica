locals {

  # Logic to use AD name provided by user input on ORM or to lookup for the AD name when running from CLI
  availability_domain = (var.ad_name != "" ? var.ad_name : data.oci_identity_availability_domain.ad.name)

  # local.use_existing_network referenced in network.tf
  use_existing_network = var.network_strategy == var.network_strategy_enum["USE_EXISTING_VCN_SUBNET"] ? true : false

  # local.is_public_subnet referenced in compute.tf
  is_public_subnet = var.subnet_type == var.subnet_type_enum["PUBLIC_SUBNET"] ? true : false

  # Local to control subscription to Marketplace image.
  mp_subscription_enabled = var.mp_subscription_enabled ? 1 : 0

  # Marketplace Image listing variables - required for subscription only
  listing_id               = var.mp_listing_id
  listing_resource_id      = var.mp_listing_resource_id
  listing_resource_version = var.mp_listing_resource_version

  is_flex_shape = var.shape == "VM.Standard.E3.Flex" ? [var.vm_flex_shape_ocpus] : []

  # Used locally to determine the correct platform image. Shape names always
  # start with either 'VM.'/'BM.' and all GPU shapes have 'GPU' as the next characters
  shape_type = lower(substr(var.shape, 3, 3))

  # Logic to choose a custom image or a marketplace image.
  image = var.mp_subscription_enabled ? var.mp_listing_resource_id : var.custom_image_id
}
