# swap: yes
sh -c "
rm /var/lib/kubelet/kubeadm-flags.env
until cat \"/var/lib/kubelet/kubeadm-flags.env\" > /dev/null;
do
    sleep 1;
done && echo 'KUBELET_EXTRA_ARGS=\"--fail-swap-on=false\"' >> \"/var/lib/kubelet/kubeadm-flags.env\"
systemctl restart kubelet " &

#swap: no
swapoff -a