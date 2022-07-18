# calicoctl
cd /usr/local/bin/
curl -o calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.21.1/calicoctl" 
chmod +x calicoctl

curl -o kubectl-calico -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.21.1/calicoctl" 
chmod +x kubectl-calico
cd $OLDPWD

# local path provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml

kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

read -p "ip: " ip && kubectl apply -f - << END
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ip-$ip
END

# minio operator
wget https://github.com/minio/operator/releases/download/v4.1.3/kubectl-minio_4.1.3_linux_amd64 -O kubectl-minio
chmod +x kubectl-minio

mv kubectl-minio /usr/local/bin/

kubectl minio init

# metrics server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kubectl-convert
wget https://dl.k8s.io/v1.22.0/bin/linux/amd64/kubectl-convert
chmod -R 777 ./kubectl-convert
chmod +X ./kubectl-convert


# victoriametrics
apt install unzip -y
mkdir victoriametrics 
cd ~/victoriametrics
export VM_VERSION=`basename $(curl -fs -o/dev/null -w %{redirect_url} https://github.com/VictoriaMetrics/operator/releases/latest)`
wget https://github.com/VictoriaMetrics/operator/releases/download/$VM_VERSION/bundle_crd.zip
unzip  bundle_crd.zip 
kubectl apply -f release/crds
kubectl apply -f release/operator/
cd $OLDPWD

# clickhouse operator
kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install.yaml

# krew
apt install git curl -y
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
echo 'export PATH="${PATH}:${HOME}/.krew/bin"' >> ~/.bashrc
export PATH="${PATH}:${HOME}/.krew/bin"


# istioctl
export STARTPWD=$PWD
mkdir istio
cd istio
rm istio-* -r
curl -L https://istio.io/downloadIstio | sh -
cd istio*
echo -n 'export PATH="${PATH}:' >> ~/.bashrc
echo -n "${PWD}" >> ~/.bashrc
echo '/bin"' >> ~/.bashrc
export PATH=$PWD/bin:$PATH
cd $STARTPWD

# istio (need istioctl)
yes | istioctl install

# rook
git clone --single-branch --branch release-1.7 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
cd $OLDPWD

# kubevirt + cdi

export VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{{print $2}}' | sed 's/,//' | xargs)
echo $VERSION
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml

kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml

VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml


# kubectl virt (requires krew)

kubectl krew install virt

# velero (requires s3 bucket)

read -p "velero s3 access: " velero_s3_access
read -p "velero s3 secret: " velero_s3_secret
read -p "velero s3 endpoint: " velero_s3_endpoint
read -p "velero s3 region: " velero_s3_region
read -p "velero s3 bucket: " velero_s3_bucket

cat <<EOF > s3_cred
[default]
aws_access_key_id=$velero_s3_access
aws_secret_access_key=$velero_s3_secret
EOF


wget https://github.com/vmware-tanzu/velero/releases/download/v1.7.1/velero-v1.7.1-linux-amd64.tar.gz
tar -zxvf velero-v1.7.1-linux-amd64.tar.gz
sudo cp velero-v1.7.1-linux-amd64/velero /usr/local/bin

velero install \
--plugins velero/velero-plugin-for-aws:v1.0.0 \
--provider aws \
--bucket $velero_s3_bucket \
--secret-file ./s3_cred \
--use-volume-snapshots=true \
--backup-location-config region=$velero_s3_region,s3ForcePathStyle="true",s3Url=$velero_s3_endpoint
rm s3_cred

# flagger
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
helm upgrade -i flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://vmsingle-vmsingle.monitoring:8429

# print master join command
echo "Master join command"
export K8S_CERT_KEYS=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)
kubeadm token create --certificate-key ${K8S_CERT_KEYS} --print-join-command

# print join command
echo "Join command"
kubeadm token create --print-join-command

# print kubeconfig
cat ~/.kube/config