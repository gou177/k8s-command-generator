# swap enable hack
kubeadm config images pull
sh -c "
rm /var/lib/kubelet/kubeadm-flags.env
until cat \"/var/lib/kubelet/kubeadm-flags.env\" > /dev/null;
do
    sleep 1;
done && echo 'KUBELET_EXTRA_ARGS=\"--fail-swap-on=false\"' >> \"/var/lib/kubelet/kubeadm-flags.env\"
systemctl restart kubelet " &
kubeadm init \
    --upload-certs \
    --pod-network-cidr=10.244.0.0/16 \
        --ignore-preflight-errors=Swap
# Enable swap ^

mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-

# join
kubeadm config images pull
sh -c "
rm /var/lib/kubelet/kubeadm-flags.env
until cat \"/var/lib/kubelet/kubeadm-flags.env\" > /dev/null;
do
    sleep 1;
done && echo 'KUBELET_EXTRA_ARGS=\"--fail-swap-on=false\"' >> \"/var/lib/kubelet/kubeadm-flags.env\"
systemctl restart kubelet " &
kubeadm join {}:6443 \
    --token yf47i1.dhn37zxcq7wzy82k \
    --discovery-token-ca-cert-hash {} \
    --control-plane \
    --certificate-key {} \
    --ignore-preflight-errors=Swap

# print join command
export K8S_CERT_KEYS=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)
kubeadm token create --certificate-key ${K8S_CERT_KEYS} --print-join-command

## slave
kubeadm token create --print-join-command
