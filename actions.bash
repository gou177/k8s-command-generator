# action: init
kubeadm init --pod-network-cidr={cidr} \
        --ignore-preflight-errors={preflighterrors}
mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/master-

# action: join
{join_cmd} --ignore-preflight-errors={preflighterrors}
