# oci-kinetica
This is a Terraform module that deploys [Kinetica](https://www.kinetica.com/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Kinetica.

This Quick Start uses [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment easy, sign up for an [OCI account](https://cloud.oracle.com/en_US/tryit) if you don't have one, and just click the button below:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-kinetica/archive/master.zip)

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

## Clone the Module
You'll first want a local copy of this repo by running:

```
git clone https://github.com/oracle-quickstart/oci-kinetica.git
cd oci-kinetica/simple
ls
```
That should give you this:

![](./images/01-git_clone.png)

We now need to initialize the directory with the module in it.  This makes the module aware of the OCI provider.  You can do this by running:

```
terraform init
```
This gives the following output:

![](./images/02-terraform_init.png)

## Deploy

First we want to run `terraform plan`. This runs through the terraform and lists
out the resources to be created based on the values in `variables.tf`.

Kinetica requires a license key and running `terraform plan` or `terraform apply`
will prompt for one. You can get a trial key by going [here](https://www.kinetica.com/trial/)
and clicking `Register&Download`.

The variables you most likely would want to change are:

- `shape`: Instance type for each worker. These templates support both CPU and GPU shapes.
- `worker_count`: Number of workers.
- `ad_number`: Which availability domain to deploy to depending on quota, zero based.
- `disk_size`: Size of the block volume(s) for each worker node in GB.
- `disk_count`: Number of block volumes per worker, multiple disks will create a RAID0 array.


If that's good, we can go ahead and apply the deploy:

```
terraform apply
```

You'll need to enter `yes` when prompted.  The apply should take several minutes
to run, and the final setup of Kinetica will happen asynchronously after this returns.

Once complete, you'll see something like this:

![](./images/04-terraform_apply.png)

You'll see 4 outputs that should look like this with different IPs:
```
Outputs:

aaw_url = http://132.145.140.206:8070
gadmin_url = http://132.145.140.206:8080
reveal_url = http://132.145.140.206:8088
worker_private_ips = 10.0.0.7,10.0.0.6,10.0.0.5
worker_public_ips = 132.145.140.206,150.136.220.242,129.213.16.31
```

Point your browser at the `gadmin_url` in the outputs. If GAdmin doesn't respond
immediately, the configuration is still finishing.

At first login with default credentials `admin/admin` you'll be prompted to set a password.

![](./images/06-login.png)
![](./images/07-pw_change.png)

You should then see the GAdmin console.

![](./images/08-gadmin.png)

You can also log into Reveal with the `reveal_url` like below. The default credentials
are again `admin/admin` and need to be changed separately from GAdmin post-login.

![](./images/09-reveal.png)

You can also log into Active Analytics Workbench with the `aaw_url` like below.
Here the credentials are shared with GAdmin, ie you can log in with `admin` and
the password you chose when resetting.

![](./images/10-aaw.png)

AAW is running against a dev sized local K8 cluster running on `kinetica-worker-0`.

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

```
terraform destroy
```

You'll need to enter `yes` when prompted.  Once complete, you'll see something like this:

![](./images/05-terraform_destroy.png)
