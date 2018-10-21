# this is based on ovn-kubernetes minion installation as described here: 
# https://gist.github.com/yuvalif/2b732a66f1903ff505fb392ed35f8d65
# this runs ovnkube as master
# run on Fedora28 as root
set -ex

# set variables
export CENTRAL_IP=`kubectl get nodes | grep master | cut -f 1 -d' '`
export CLUSTER_IP_SUBNET=10.244.0.0/16
export NODE_NAME=`ip -o addr show|grep -v docker |awk '{ print $4 }'|grep -v '^127' |grep -v '^fe80' |grep -v ':' | grep -v "10.244" | head -n 1 |cut -f1 -d/`
export TOKEN=abcdef.1234567890123456
export SERVICE_IP_SUBNET=`kubectl cluster-info dump  | grep service-cluster | cut -d'=' -f2 | cut -d'"' -f1`

# run the ovn-kubernetes daemon
nohup ovnkube -k8s-kubeconfig /root/.kube/config \
    -net-controller \
    -loglevel=4 \
    -logfile="/var/log/openvswitch/ovnkube.log" \
    -k8s-apiserver="http://$CENTRAL_IP:8080" \
    -init-node=$NODE_NAME \
    -nodeport \
    -init-gateways \
    -nb-address="tcp://$CENTRAL_IP:6641" \
    -sb-address="tcp://$CENTRAL_IP:6642" \
    -k8s-token="$TOKEN" \
    -service-cluster-ip-range=$SERVICE_IP_SUBNET \
    -cluster-subnet=$CLUSTER_IP_SUBNET 2>&1 &