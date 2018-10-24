# Single Network
This is to test the basic functionality of ovn-kubernetes when only the default networks exists.
## Single Node
To install a single node running both master and minion for k8s as well as ovn-kubernetes use:
```bash
./install-ovn-kubernetes.sh
```
And then run:
```bash
./run-ovn-kubernetes.sh
```
> The ovn-kubernetes log will be at ```/var/log/openvswitch/ovnkube.log```
To create the pods, use:
```
kubectl create -f cirros-pod.yaml
kubectl create -f another-cirros-pod.yaml
```
To see that the pods are running and have IPs in the correct range, use:
```bash
kubectl get pods -o wide
```
To test connectivity we want to test ping between the pods:
```bash
CIRROS_IP=`kubectl exec cirros ip addr | grep "10.244" | cut -f1 -d/ | awk '{print $2}'`
kubectl exec another-cirros ping $CIRROS_IP
```
## Multiple Nodes
To install multiple nodes running one master for both k8s and ovn-kubernetes and minions use, on the master:
```bash
./install-ovn-kubernetes-master.sh
./run-ovn-kubernetes-master.sh
```
And on each minion (note that some interaction will be needed):
```bash
./install-ovn-kubernetes-minion.sh <master ip>
./run-ovn-kubernetes-minion.sh
```
And then run (on master or minion):
```bash
kubectl create -f cirros-pod.yaml
kubectl create -f another-cirros-pod.yaml
```
To see that the pods are running and have IPs in the correct range, use:
```bash
kubectl get pods -o wide
```
To test connectivity we want to test ping between the pods:
```bash
CIRROS_IP=`kubectl exec cirros ip addr | grep "10.244" | cut -f1 -d/ | awk '{print $2}'`
kubectl exec another-cirros ping $CIRROS_IP
```
### Different Pods on Different Nodes
TODO

# Multiple Network
This is to tests the enhanced functionality of multiple networks with ovn-kubernetes, as enhanced by [this fork](https://github.com/AlonaKaplan/ovn-kubernetes)
## Single Node
To install a single node running both master and minion for k8s as well as ovn-kubernetes use:
```bash
./install-ovn-kubernetes-multinet.sh
```
Because an additional network is needed, an additional switch needs to be added to the node. This is done by:
```bash
TODO
```
Now run ovn-kubernetes (similarly to the single net case):
```
./run-ovn-kubernetes.sh
```
> The ovn-kubernetes log will be at ```/var/log/openvswitch/ovnkube.log```
Now the NetworkAttachmentDefinitions CRD need to be created:
```
kubectl create 
```
To create the pods, use:
```
kubectl create -f cirros-pod-multinet.yaml
kubectl create -f another-cirros-pod-multinet.yaml
```
To test connectivity we want to test ping between the pods:
```bash
CIRROS_IP=`kubectl exec cirros-multinet ip addr | grep "10.10" | cut -f1 -d/ | awk '{print $2}'`
kubectl exec another-cirros-multinet ping $CIRROS_IP
```
## Multiple Node
TODO
