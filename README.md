# oci-quickstart-kinetica
This is a Terraform module that deploys [Kinetica](https://www.kinetica.com/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Kinetica.

This repo is under active development.  Building open source software is a community effort.  We're excited to engage with the community building this.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo by running:

    git clone https://github.com/oracle/oci-quickstart-kinetica.git

## Deploy
The TF templates here can be deployed by running the following commands:
```
cd oci-quickstart-kinetica/simple
terraform init
terraform plan
terraform apply # will prompt to continue
```

The output of `terraform apply` should look like:
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

GAdmin URL = http://132.145.215.17:8080
Reveal URL = http://132.145.215.17:8088
Worker server private IPs = 10.0.0.2
Worker server public IPs = 132.145.215.17
```
