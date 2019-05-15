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
# cuda91 is correct for all GPU shapes as all GPUs are either V100/P100
yum install -y gpudb-cuda91-license.x86_64

# create default persist dir
# /data will be mount pt for block storage if it exists
echo "Create persist dir"
mkdir -p /data/gpudb/persist
chown -R gpudb:gpudb /data/gpudb

#
# Exit early here if not first/head node?
#

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
NUM_GPU=$(nvidia-smi -L | wc -l)
echo "Found the following number of GPUS: $NUM_GPU"

echo "Loop over hostnames"
for i in "${HOST_NAMES[@]}"; do
  echo "Hostname: $i"
  #Set rank0 IP to internal hostname

  if [ $NODECOUNTER -eq 0 ]
  then
   sed -i -E "s/rank0_ip_address =.*/rank0_ip_address = $i/g" $GPUDB_CONF_FILE
  fi
  echo "Loop over available GPUs"
  for n in `seq 0 $((NUM_GPU-1))`; do
    echo "rank$RANKNUM.taskcalc_gpu = $n" >> $GPUDB_CONF_FILE
    RANKNUM=$RANKNUM+1
  done

  #skip node 1 else add to hosts file
   if [ $NODECOUNTER -gt 0 ]
   then
      echo "$i slots=$NUM_GPU max_slots=$NUM_GPU" >>"$GPUDB_HOSTS_FILE"
   else
      let FIRST_HOST_GPU=$NUM_GPU+1
      echo "$i slots=$FIRST_HOST_GPU max_slots=$FIRST_HOST_GPU" >"$GPUDB_HOSTS_FILE"
   fi
  NODECOUNTER=$NODECOUNTER+1
done
sed -i -E "s/number_of_ranks =.*/number_of_ranks = $RANKNUM/g" $GPUDB_CONF_FILE

#debug
cp $GPUDB_CONF_FILE $GPUDB_CONF_FILE.mine

# Start service
echo "Starting service"
systemctl enable gpudb_host_manager
systemctl start gpudb_host_manager
#sleep 10s
#systemctl start gpudb_host_manager
