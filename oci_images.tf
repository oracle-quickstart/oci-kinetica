variable "marketplace_source_images" {
  type = map(object({
    ocid                  = string
    is_pricing_associated = bool
    compatible_shapes     = set(string)
  }))
  default = {
    main_mktpl_image = {
      ocid                  = "ocid1.image.oc1..aaaaaaaaewd73p7gagjkemzjs6k63bkl4xaeyennh3qv27dvow2h6l4m5zeq"
      is_pricing_associated = false
      compatible_shapes = [
        "VM.Standard.E2.1",
        "VM.Standard.E2.2",
        "VM.Standard.E2.4",
        "VM.GPU3.4",
        "VM.Standard2.16",
        "VM.Standard2.24",
        "VM.GPU3.1",
        "VM.GPU2.1",
        "VM.GPU3.2",
        "VM.DenseIO2.8",
        "VM.Standard2.8",
        "VM.Standard2.4",
        "VM.DenseIO2.16",
        "VM.DenseIO2.24",
        "VM.Standard.E2.8",
        "VM.Standard2.1",
        "VM.Standard2.2"
      ]
    }
  }
}
