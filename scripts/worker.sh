echo "Running $0"

echo "Got the parameters:"
echo password $password

public_ip=$(oci-public-ip -j | jq '.publicIp' | tr -d '"')
private_ip=$(hostname -I)

#######################################################
##################### Disable firewalld ###############
#######################################################
systemctl stop firewalld
systemctl disable firewalld

#######################################################
##################### Install/config Kinetica #########
#######################################################
