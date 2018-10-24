# on Fedora28 as root

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <master IP>"
    exit 1
fi

set -ex

MASTER_IP=$1

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
export TOKEN=abcdef.1234567890123456
export NODE_NAME=`ip -o addr show|grep -v docker |awk '{ print $4 }'|grep -v '^127' |grep -v '^fe80' |grep -v '^::' |head -n 1 |cut -f1 -d/`

# join the k8s cluster
# the actual values should be taken from the output of "kubeadm init" command on the master
kubeadm join ${MASTER_IP}:6443 --token $TOKEN --node-name $NODE_NAME --discovery-token-unsafe-skip-ca-verification

# install and run ovs/ovn
dnf install -y openvswitch openvswitch-ovn-*
systemctl start openvswitch && systemctl enable openvswitch

# start the ovn controler on a k8s minion node
/usr/share/openvswitch/scripts/ovn-ctl start_controller

# build and install ovn-kubernetes from source
dnf install -y git go make
git clone https://github.com/openvswitch/ovn-kubernetes
cd ovn-kubernetes/go-controller
make && make install

# seems like a bug in parsing the default file, just truncate it
cp /etc/openvswitch/ovn_k8s.conf /etc/openvswitch/ovn_k8s.conf.bak
echo "" > /etc/openvswitch/ovn_k8s.conf

# to run kubectl from inside the node copy config
mkdir -p /$USER/.kube && scp root@${MASTER_IP}:/etc/kubernetes/admin.conf /$USER/.kube/config
