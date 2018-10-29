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
ovn-nbctl ls-add an-ovn-switch1
ovn-nbctl ls-add an-ovn-switch2
ovn-nbctl set logical_switch an-ovn-switch1 other-config:subnet=10.0.0.0/24
ovn-nbctl set logical_switch an-ovn-switch2 other-config:subnet=10.10.0.0/24
```
Now run ovn-kubernetes (similarly to the single net case):
```
./run-ovn-kubernetes.sh
```

> The ovn-kubernetes log will be at ```/var/log/openvswitch/ovnkube.log```

Now the NetworkAttachmentDefinitions CRDs need to be created:
```bash
kubectl create ovn-network1.yaml 
kubectl create ovn-network2.yaml 
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
### Connect to Physical Network

> Currently blocked by [OVN issue](https://bugzilla.redhat.com/show_bug.cgi?id=1643749)
> Would work only if static MAC is provided in pod annotation. For example:
> ```yaml
> annotations:
>    switches: a-physnet-switch
>    k8s.v1.cni.cncf.io/networks: an-ovn-physnet
>    ovn_extra: '{"a-physnet-switch":{"mac_address":"0a:00:00:00:00:01"}}'
> ```

For that, it is recommended to use a host with 2 physical interfaces. Assuming the 2nd interface is "eth1", first step is to greate an ovs bridge:
```bash
ovs-vsctl add-br breth1
```
And associate with an ovn physical network:
```bash
ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=phyNet:breth1
```
Now create the ovn logical bridge and ports (for physical network):
```bash
ovn-nbctl ls-add a-physnet-switch
ovn-nbctl lsp-add a-physnet-switch physport-localnet
ovn-nbctl lsp-set-addresses physport-localnet unknown
ovn-nbctl lsp-set-type physport-localnet localnet
ovn-nbctl lsp-set-options physport-localnet network_name=phyNet
```
Last, associate the ovs bridge with the physical NIC:
```bash
ovs-vsctl add-port breth1 eth1
```
Now create the ```NetworkAttachmentDefinition``` CRD for that new switch:
```bash
kubectl create -f ovn-physnet.yaml 
```
And create a pod that uses it:
```bash
kubectl create -f cirros-pod-physnet.yaml
```

## Multiple Node
TODO
