echo "Kinetica install/setup"


#######################################################
##################### Disable firewalld ###############
#######################################################
systemctl stop firewalld
systemctl disable firewalld

#######################################################
##################### Install/config Kinetica #########
#######################################################

echo "Running yum install"
wget -O /etc/yum.repos.d/kinetica-7.1.repo http://repo.kinetica.com/yum/7.1/CentOS/8/x86_64/kinetica-7.1.repo

if [[ $shape == *"GPU"* ]]; then
  echo "Running on GPU shape, installing cuda build..."
  # cuda91 is correct for all GPU shapes as all GPUs are either V100/P100
  yum install -y gpudb-cuda91-license.x86_64
  NUM_GPU=$(nvidia-smi -L | wc -l)
  echo "Found the following number of GPUS: $NUM_GPU"
else
  echo "Running on non-GPU shape, installing intel build..."
  yum install -y numactl gpudb-intel-license.x86_64
  NUM_NUMA=$(lscpu | awk -F":" '/^NUMA node\(s\)/ { print $2 }' | tr -d ' ')
  echo "Found the following number of NUMA nodes: $NUM_NUMA"
fi

# create default persist dir
# /data will be mount pt for block storage if it exists
echo "Create persist dir"
mkdir -p /data/gpudb/persist
chown -R gpudb:gpudb /data/gpudb

#
# Exit early here if not first/head node?
#

if [ $(hostname) != "kinetica-worker-0" ]
then
   echo "Not running on head node, stopping gpudb, exiting early, waiting to join cluster"
   systemctl stop gpudb
   exit 0
fi

# echo "Creating self-signed cert"
# openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
#   -keyout /opt/gpudb/core/etc/key.pem \
#   -out /opt/gpudb/core/etc/cert.pem \
#   -subj "/CN=example.com" \
#   -addext "subjectAltName=DNS:example.com,DNS:www.example.net,IP:$public_ip"
#
# chown gpudb:gpudb /opt/gpudb/core/etc/{key.pem,cert.pem}
# chmod 600 /opt/gpudb/core/etc/{key.pem,cert.pem}

echo "Changing gpudb.conf"
GPUDB_CONF_FILE="/opt/gpudb/core/etc/gpudb.conf"
ENABLE_ODBC="true"
ENABLE_CARAVEL="true"
ENABLE_KIBANA="false"
HEAD_NODE_IP=$public_ip
LICENSE_KEY=$(echo $json | jq -r '.metadata.license_key')
echo "key: " $LICENSE_KEY

cp $GPUDB_CONF_FILE $GPUDB_CONF_FILE.bak

sed -i -E "s/host0.address =.*/host0.address = ${private_ip}/g" $GPUDB_CONF_FILE
sed -i -E "s/host0.public_address =.*/host0.public_address = ${HEAD_NODE_IP}/g" $GPUDB_CONF_FILE
sed -i -E "s/host0.host_manager_public_url =.*/host0.host_manager_public_url = http:\/\/${HEAD_NODE_IP}:9300/g" $GPUDB_CONF_FILE

#sed -i -E "s/head_ip_address =.*/head_ip_address = ${HEAD_NODE_IP}/g" $GPUDB_CONF_FILE
sed -i -E "s/enable_caravel =.*/enable_caravel = ${ENABLE_CARAVEL}/g" $GPUDB_CONF_FILE
sed -i -E "s/enable_odbc_connector =.*/enable_odbc_connector = ${ENABLE_ODBC}/g" $GPUDB_CONF_FILE
sed -i -E "s:persist_directory = .*:persist_directory = /data/gpudb/persist:g" $GPUDB_CONF_FILE
sed -i -E "s:license_key =.*:license_key = ${LICENSE_KEY}:g" $GPUDB_CONF_FILE
sed -i -E "s/enable_text_search =.*/enable_text_search = true/g" $GPUDB_CONF_FILE


# testing
#sed -i -E "s:use_https = .*:use_https = true:g" $GPUDB_CONF_FILE
#sed -i -E "s:https_key_file = .*:https_key_file = /opt/gpudb/core/etc/key.pem:g" $GPUDB_CONF_FILE
#sed -i -E "s:https_cert_file = .*:https_cert_file = /opt/gpudb/core/etc/cert.pem:g" $GPUDB_CONF_FILE

# Build hostname array
worker_count=$(echo $json | jq -r '.metadata.config.worker_count')
declare -a HOST_NAMES
for n in `seq 0 $((worker_count-1))`; do
   HOST_NAMES[$n]="kinetica-worker-$n"
done

#Setup ranks
#Setup rank 0
sed -i -E "s/rank0.numa_node = .*/rank0.numa_node = 0/g" $GPUDB_CONF_FILE
#Remove the other settings
sed -i -E "s/rank.*.taskcalc_gpu =.*//g" $GPUDB_CONF_FILE
#Remove empty lines at end of file
sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $GPUDB_CONF_FILE
# mark additional hosts section
sed -i -E "s/host0.accepts_failover = false/host0.accepts_failover = false\n\n#add hosts/g" $GPUDB_CONF_FILE

#Setup the rest
declare -i RANKNUM=1
declare -i NODECOUNTER=0

echo "Loop over hostnames to add hosts"
configstring=""
for i in "${HOST_NAMES[@]}"; do
  echo "Hostname: $i"
  if [[ $NODECOUNTER -eq 0 ]]; then
    echo "Not adding head node..."
    ((NODECOUNTER++))
    continue
  fi

  ip=$(host $i | awk '/has address/ { print $4 }')
  echo "IP: $ip"
  configstring+="host$NODECOUNTER.address = $ip\n"
  configstring+="host$NODECOUNTER.public_address = $ip\n"
  configstring+="host$NODECOUNTER.host_manager_public_url = http://$ip:9300\n"
  configstring+="host$NODECOUNTER.ram_limit = -1\n"
  configstring+="host$NODECOUNTER.gpus =\n"
  configstring+="host$NODECOUNTER.accepts_failover = false\n\n"

  ((NODECOUNTER++))
done
echo -e $configstring
sed -i -E "s,#add hosts,#add hosts\n$configstring,g" $GPUDB_CONF_FILE


# cleanup
sed -i -E "s/#removed rank2.host//g" $GPUDB_CONF_FILE

echo "Loop over ranks to add hosts"
configstring="rank1.host = host0\n"
for i in `seq 2 $worker_count`; do
  echo "Setting rank$i to host$((i-1))"
  configstring+="rank$i.host = host$((i-1))\n"
done
echo -e $configstring
sed -i -E "s/rank1.host = host0/$configstring/g" $GPUDB_CONF_FILE

#debug
cp $GPUDB_CONF_FILE $GPUDB_CONF_FILE.cloudinit

# Start services
echo "Sleeping 30s..."
sleep 30s
echo "Enabling/Starting gpudb..."
service gpudb enable
service gpudb start
sleep 30s
/etc/init.d/gpudb restart all
sleep 30s
/etc/init.d/gpudb restart all

# AAW and k8
#################################
#
# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
# [kubernetes]
# name=Kubernetes
# baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
# enabled=1
# gpgcheck=1
# repo_gpgcheck=1
# gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
# EOF
#
# # pulls in deps, eg docker
# yum install -y --enablerepo=kubernetes kubelet kubeadm kubectl docker-engine
#
# # selinux permissive now and in config
# /usr/sbin/setenforce 0
# sed -i -E "s/SELINUX=.*/SELINUX=permissive/g" /etc/selinux/config
# swapoff -a
# modprobe br_netfilter
# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
#
# systemctl enable docker
# systemctl start docker
#
# systemctl enable kubelet
# systemctl start kubelet
#
# kubeadm init
#
# # root
# mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config
# # opc
# mkdir -p ~opc/.kube
# cp -i /etc/kubernetes/admin.conf ~opc/.kube/config
# chown -R opc:opc $HOME/.kube
#
# kubectl get nodes
# export kubever=$(kubectl version | base64 | tr -d '\n')
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
# # sleep 1m; kubectl get nodes
#
# #cpu/gpu logic
# yum install -y kinetica-ml.x86_64
#
# mkdir -p /opt/gpudb/.kube
# cp /etc/kubernetes/admin.conf /opt/gpudb/.kube/config
# chown -R gpudb:gpudb /opt/gpudb/.kube
#
# # sed over /opt/gpudb/kml/etc/kml.ini and /opt/gpudb/kml/etc/application.properties
# kml_ini="/opt/gpudb/kml/etc/kml.ini"
# cp $kml_ini $kml_ini.bak
# sed -i -E "s/api_connection=.*/api_connection=http:\/\/${public_ip}:9187/g" $kml_ini
# sed -i -E "s/db_connection=.*/db_connection=http:\/\/${private_ip}:9191/g" $kml_ini
# sed -i -E "s:kube_config=.*:kube_config=/opt/gpudb/.kube/config:g" $kml_ini
#
# kml_props="/opt/gpudb/kml/etc/application.properties"
# cp $kml_props $kml_props.bak
# sed -i -E "s/kinetica.api-url=.*/kinetica.api-url=http:\/\/${private_ip}:9191/g" $kml_props
# sed -i -E "s/kinetica.hostmanager-api-url=.*/kinetica.hostmanager-api-url=http:\/\/${private_ip}:9300/g" $kml_props
# sed -i -E "s/kinetica.kml-api-url=.*/kinetica.kml-api-url=http:\/\/${public_ip}:9187\/kml/g" $kml_props
#
# service kml restart
