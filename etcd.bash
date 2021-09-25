# memberlist
etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt     \
  --cert=/etc/kubernetes/pki/etcd/server.crt     \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# healtz
etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt     \
  --cert=/etc/kubernetes/pki/etcd/server.crt     \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# remove member
etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt     \
  --cert=/etc/kubernetes/pki/etcd/server.crt     \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member remove  {}