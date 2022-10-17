#!/usr/bin/env bash

echo "Gathering metadata..."

public_ip=$(oci-public-ip -j | grep "Address" | jq -r '.[0]."IP Address"')
private_ip=$(hostname -i)

json=$(curl -sSL http://169.254.169.254/opc/v1/instance/)
shape=$(echo $json | jq -r .shape)

echo "Pub/priv IP: $public_ip $private_ip $shape"
echo "Full metadata: $json"
echo "Shape: $shape"

echo "dnf update..."
sudo dnf -y update

echo "Kinetica install/setup"

echo "Open http ports in firewalld"
sudo firewall-cmd --permanent --add-port={8000,8080,8082,8088}/tcp && firewall-cmd --reload
sudo firewall-cmd --list-ports

GPUDB_CONF_FILE="/opt/gpudb/core/etc/gpudb.conf"
echo "Running yum install"
sudo wget -O /etc/yum.repos.d/kinetica-7.1.repo http://repo.kinetica.com/yum/7.1/CentOS/8/x86_64/kinetica-7.1.repo

if [[ $shape == *"GPU"* ]]; then
  echo "Running on GPU shape, installing cuda build..."
  # cuda91 is correct for all GPU shapes as all GPUs are either V100/P100, T4 on rover
  sudo dnf install -y numactl gpudb-cuda-license.x86_64
  NUM_GPU=$(nvidia-smi -L | wc -l)
  echo "Found the following number of GPUS: $NUM_GPU"
else
  echo "Running on non-GPU shape, installing intel build..."
  sudo dnf install -y numactl gpudb-intel-license.x86_64
  NUM_NUMA=$(lscpu | awk -F":" '/^NUMA node\(s\)/ { print $2 }' | tr -d ' ')
  echo "Found the following number of NUMA nodes: $NUM_NUMA"
fi

sudo sed -i -E "s/rank2.host =.*/#removed rank2.host/g" $GPUDB_CONF_FILE

echo "Switch default port 9003 due to collision with osms-agent"
sudo sed -i -E "s/set_monitor_proxy_port =.*/set_monitor_proxy_port = 9013 \n#changed due to collision with osms-agent/g" $GPUDB_CONF_FILE
sudo systemctl stop gpudb
sudo systemctl enable gpudb
