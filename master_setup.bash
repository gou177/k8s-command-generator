# flannel
kubeadm config images pull
sh -c "
rm /var/lib/kubelet/kubeadm-flags.env
until cat \"/var/lib/kubelet/kubeadm-flags.env\" > /dev/null;
do
    sleep 1;
done && echo 'KUBELET_EXTRA_ARGS=\"--fail-swap-on=false\"' >> \"/var/lib/kubelet/kubeadm-flags.env\"
systemctl restart kubelet " &
kubeadm init --pod-network-cidr=10.244.0.0/16 \
        --ignore-preflight-errors=Swap
mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# calico
kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-



