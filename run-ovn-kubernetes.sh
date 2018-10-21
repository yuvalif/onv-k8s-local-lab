# this is based on ovn-kubernetes installation as described here: https://gist.github.com/yuvalif/b79add8202de69202c0d2bc6c2b67e00
# this runs ovnkube as master and minion
# run on Fedora28 as root
set -ex

# set variables
export CENTRAL_IP=`ip -o addr show|grep -v docker |awk '{ print $4 }'|grep -v '^127' |grep -v '^fe80' |grep -v '^::' |head -n 1 |cut -f1 -d/`
export CLUSTER_IP_SUBNET=10.244.0.0/16
export NODE_NAME=$CENTRAL_IP
export TOKEN=abcdef.1234567890123456
export SERVICE_IP_SUBNET=`kubectl cluster-info dump  | grep service-cluster | cut -d'=' -f2 | cut -d'"' -f1`

# run the ovn-kubernetes daemon
nohup ovnkube -k8s-kubeconfig /etc/kubernetes/admin.conf \
    -net-controller \
    -loglevel=4 \
    -logfile="/var/log/openvswitch/ovnkube.log" \
    -k8s-apiserver="http://$CENTRAL_IP:8080" \
    -init-master=$NODE_NAME \
    -init-node="$NODE_NAME"  \
    -nodeport \
    -nb-address="tcp://$CENTRAL_IP:6641" \
    -sb-address="tcp://$CENTRAL_IP:6642" \
    -k8s-token="$TOKEN" \
    -init-gateways \
    -service-cluster-ip-range=$SERVICE_IP_SUBNET \
    -cluster-subnet=$CLUSTER_IP_SUBNET 2>&1 &
