#!/usr/bin/env bash

echo "Gathering metadata..."

public_ip=$(oci-public-ip -j | jq -r '.publicIp')
private_ip=$(hostname -i)

json=$(curl -sSL http://169.254.169.254/opc/v1/instance/)
shape=$(echo $json | jq -r .shape)

echo "Pub/priv IP: $public_ip $private_ip $shape"
echo "Full metadata: $json"
echo "Shape: $shape"

echo "Kinetica install/setup"

systemctl stop firewalld
systemctl disable firewalld

echo "Running yum install"
wget -O /etc/yum.repos.d/kinetica-7.1.repo http://repo.kinetica.com/yum/7.1/CentOS/7/x86_64/kinetica-7.1.repo

if [[ $shape == *"GPU"* ]]; then
  echo "Running on GPU shape, installing cuda build..."
  # cuda91 is correct for all GPU shapes as all GPUs are either V100/P100, T4 on rover
  yum install -y gpudb-cuda91-license.x86_64
  NUM_GPU=$(nvidia-smi -L | wc -l)
  echo "Found the following number of GPUS: $NUM_GPU"
else
  echo "Running on non-GPU shape, installing intel build..."
  yum install -y gpudb-intel-license.x86_64
  NUM_NUMA=$(lscpu | awk -F":" '/^NUMA node\(s\)/ { print $2 }' | tr -d ' ')
  echo "Found the following number of NUMA nodes: $NUM_NUMA"
fi
