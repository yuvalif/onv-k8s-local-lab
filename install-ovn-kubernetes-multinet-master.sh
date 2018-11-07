# this script install k8s and the ovn-kubernetes cni to run on a master machine
# acting as master for k8s and for ovn-kubernetes
# tested on Fedora28 as root

set -ex

# install and enable docker
dnf update -y
dnf install -y docker
systemctl enable docker && systemctl start docker

# permanently disable selinux
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# permanently disable swap file
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# disable firewalld
systemctl stop firewalld && systemctl disable firewalld

# set k8s repo
if [ ! -f /etc/yum.repos.d/kubernetes.repo ]; then
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
fi

# install k8s
dnf install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet && systemctl start kubelet

# set variables
export CENTRAL_IP=`ip -o addr show|grep -v docker |awk '{ print $4 }'|grep -v '^127' |grep -v '^fe80' |grep -v '^::' |head -n 1 |cut -f1 -d/`
export CLUSTER_IP_SUBNET=10.244.0.0/16
export NODE_NAME=$CENTRAL_IP

export TOKEN=abcdef.1234567890123456

# start k8s with a token and IP based hostname
kubeadm init --pod-network-cidr=$CLUSTER_IP_SUBNET --token=$TOKEN --node-name=$NODE_NAME

# to run kubectl from inside the node copy config
mkdir -p /$USER/.kube && cp /etc/kubernetes/admin.conf /$USER/.kube/config

# install flannel as the default CNI
kubectl create -f https://raw.githubusercontent.com/intel/multus-cni/master/images/flannel-daemonset.yml

# install multus to allow multiple CNIs
kubectl create -f https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml

# taint master - so we can run pods there
kubectl taint nodes --all node-role.kubernetes.io/master-

export SERVICE_IP_SUBNET=`kubectl cluster-info dump  | grep service-cluster | cut -d'=' -f2 | cut -d'"' -f1`

# install and run ovs/ovn
dnf install -y openvswitch openvswitch-ovn-*
systemctl start openvswitch && systemctl enable openvswitch

# start the central components on a k8s master node
/usr/share/openvswitch/scripts/ovn-ctl start_northd
/usr/share/openvswitch/scripts/ovn-ctl start_controller

# build and install ovn-kubernetes from source
dnf install -y git go make
git clone https://github.com/AlonaKaplan/ovn-kubernetes 2> /dev/null || (cd ovn-kubernetes; git pull)
cd ovn-kubernetes/go-controller
make && make install

# seems like a bug in parsing the default file, just truncate it
cp /etc/openvswitch/ovn_k8s.conf /etc/openvswitch/ovn_k8s.conf.bak
echo "" > /etc/openvswitch/ovn_k8s.conf

