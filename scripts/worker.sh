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
wget -O /etc/yum.repos.d/kinetica-7.0.repo http://repo.kinetica.com/yum/7.0/CentOS/7/x86_64/kinetica-7.0.repo

if [[ $shape == *"GPU"* ]]; then
  echo "Running on GPU shape, installing cuda build..."
  # cuda91 is correct for all GPU shapes as all GPUs are either V100/P100
  yum install -y gpudb-cuda91-license.x86_64
  NUM_GPU=$(nvidia-smi -L | wc -l)
  echo "Found the following number of GPUS: $NUM_GPU"
else
  echo "Running on non-GPU shape, installing intel build..."
  yum install -y gpudb-intel-license.x86_64
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
   echo "Not running on head node, starting host manager, exiting early"
   systemctl enable gpudb_host_manager
   systemctl start gpudb_host_manager
   exit 0
fi

echo "Creating self-signed cert"
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 \
 -keyout /opt/gpudb/core/etc/key.pem \
 -out /opt/gpudb/core/etc/cert.pem
chown gpudb:gpudb /opt/gpudb/core/etc/{key.pem,cert.pem}
chmod 600 /opt/gpudb/core/etc/{key.pem,cert.pem}

echo "Changing gpudb.conf"
GPUDB_CONF_FILE="/opt/gpudb/core/etc/gpudb.conf"
GPUDB_HOSTS_FILE="/opt/gpudb/core/etc/hostsfile"
ENABLE_ODBC="True"
ENABLE_CARAVEL="True"
ENABLE_KIBANA="False"
HEAD_NODE_IP=$public_ip
LICENSE_KEY=$(echo $json | jq -r '.metadata.license_key')
echo "key: " $LICENSE_KEY

cp $GPUDB_CONF_FILE $GPUDB_CONF_FILE.bak
touch $GPUDB_HOSTS_FILE
chown gpudb:gpudb $GPUDB_HOSTS_FILE

sed -i -E "s/head_ip_address =.*/head_ip_address = ${HEAD_NODE_IP}/g" $GPUDB_CONF_FILE
sed -i -E "s/enable_caravel =.*/enable_caravel = ${ENABLE_CARAVEL}/g" $GPUDB_CONF_FILE
sed -i -E "s/enable_odbc_connector =.*/enable_odbc_connector = ${ENABLE_ODBC}/g" $GPUDB_CONF_FILE
sed -i -E "s:persist_directory = .*:persist_directory = /data/gpudb/persist:g" $GPUDB_CONF_FILE
sed -i -E "s:license_key =.*:license_key = ${LICENSE_KEY}:g" $GPUDB_CONF_FILE

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

#Setup the rest
declare -i RANKNUM=1
declare -i NODECOUNTER=0

echo "Loop over hostnames"
for i in "${HOST_NAMES[@]}"; do
  echo "Hostname: $i"
  ip=$(host $i | awk '/has address/ { print $4 }')
  echo "IP: $ip"

  if [ $NODECOUNTER -eq 0 ]
  then
    # Set rank0 IP to internal hostname
   sed -i -E "s/rank0_ip_address =.*/rank0_ip_address = $ip/g" $GPUDB_CONF_FILE
   # Start building RANK_HOSTS string
   RANK_HOSTS='rank0.host = '$ip'\n'
  fi

  if [[ $shape == *"GPU"* ]]; then
    echo "Running on GPU shape"
    echo "Loop over available GPUs"
    for n in `seq 0 $((NUM_GPU-1))`; do
      echo "rank$RANKNUM.taskcalc_gpu = $n" >> $GPUDB_CONF_FILE
      # Add each GPU rank to RANK_HOSTS
      RANK_HOSTS+='rank'$RANKNUM'.host = '$ip'\n'
      RANKNUM=$RANKNUM+1
    done
  else
    echo "Running on non-GPU shape"
    echo "Loop over NUMA nodes"
    for n in `seq 0 $((NUM_NUMA-1))`; do
      echo "rank$RANKNUM.base_numa_node = $n" >> $GPUDB_CONF_FILE
      # Add each NUMA rank to RANK_HOSTS
      RANK_HOSTS+='rank'$RANKNUM'.host = '$ip'\n'
      RANKNUM=$RANKNUM+1
    done
  fi


  # Skip node 1 else add to hosts file
   if [ $NODECOUNTER -gt 0 ]
   then
      echo "$ip slots=$NUM_GPU max_slots=$NUM_GPU" >>"$GPUDB_HOSTS_FILE"
   else
      let FIRST_HOST_GPU=$NUM_GPU+1
      echo "$ip slots=$FIRST_HOST_GPU max_slots=$FIRST_HOST_GPU" >"$GPUDB_HOSTS_FILE"
   fi
  NODECOUNTER=$NODECOUNTER+1
done
sed -i -E "s/number_of_ranks =.*/number_of_ranks = $RANKNUM/g" $GPUDB_CONF_FILE

# Delete rankX.host defaults
sed -i -E '/rank1.host = 127.0.0.1/d' $GPUDB_CONF_FILE
sed -i -E '/rank2.host = 127.0.0.1/d' $GPUDB_CONF_FILE
# Replace with built RANK_HOSTS
sed -i -E "s~rank0.host = 127.0.0.1~${RANK_HOSTS}~g" $GPUDB_CONF_FILE

#debug
cp $GPUDB_CONF_FILE $GPUDB_CONF_FILE.mine

# Start service
echo "Starting services"
systemctl enable gpudb_host_manager
systemctl start gpudb_host_manager
sleep 10s

service gpudb start
