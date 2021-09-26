systemctl stop kubelet
systemctl stop docker
systemctl stop containerd
yes | kubeadm reset
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
apt install net-tools -y
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ifconfig vxlan.calico down
ip link delete cni0
ip link delete flannel.1
ip link delete vxlan.calico