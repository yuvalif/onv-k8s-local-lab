# onv-k8s-local-lab
Scripts for setting up VMs running k8s with OVN CNI.

## Install
- ```install-ovn-kubernetes.sh```: install ovn-kubernetes master and minion on the same node. Install k8s as a single node. Only default pod network is supported. This is for regression testing.
- ```install-ovn-kubernetes-multinet.sh```: install ovn-kubernetes master and minion on the same node. Install k8s as a single node. Multiple networks are supported via ```multus```, and the code changes to ovn-kubernetes. 
- ```install-ovn-kubernetes-master.sh```: install ovn-kubernetes master and k8s master. Only default pod network is supported.
- ```install-ovn-kubernetes-minion.sh```: install ovn-kubernetes minion and k8s node. Only default pod network is supported.
- ```install-ovn-kubernetes-master-multinet.sh```: install ovn-kubernetes master and k8s master.Multiple networks are supported via ```multus```, and the code changes to ovn-kubernetes.
- ```install-ovn-kubernetes-minion-multinet.sh```: install ovn-kubernetes master and k8s master.Multiple networks are supported via ```multus```, and the code changes to ovn-kubernetes.

> Notes:
> - In all cases ```multus``` conf must be the first file in the ```/etc/cni/net.d``` directory, on the node where pods are expected to run (minion or master_minion)
> - Default ```multus``` network is ```flannel```, so that ovn-kubernetes is 2ndary only, to test ovn-kubernetes as primary as well, change the ```multus``` conf file under ```/etc/cni/net.d```

## Run
- ```run-ovn-kubernetes.sh```: run ovnkube on node which is both master and minion. Both single and multi-net
- ```run-ovn-kubernetes-master.sh```: run ovnkube on node which is both master and minion. Both single and multi-net
- ```run-ovn-kubernetes-minion.sh```: run ovnkube on node which is both master and minion. Both single and multi-net

## Test
see tests.md
