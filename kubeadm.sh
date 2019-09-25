#! /bin/bash

if
  [[ "${USER:-}" != "root" ]]
then
  echo "This script works only with root  user, it won't work with normal user. Please log in as root  user and try again." >&2
  exit 1
fi

if [[ nproc  -eq  1 ]]
then
  echo "This script works only with machine which has more than 2 CPU's. Please use the machine which has 2 CPU's and try again." >&2
  exit 1
fi
echo "Turning off the swap, if there is any"

swapoff -a
set -e
echo "Installing Docker.."
apt-get update
apt-get install -y docker.io
apt-get update & \
apt-get install apt-transport-https -y \
        curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "Installing Kubeadm..."

apt-get update
apt-get install -y kubelet kubeadm kubectl

echo "Creating the K8S cluster.."
#kubeadm init --pod-network-cidr=192.168.0.0/16

kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Installing the flannel networking.."

#echo "Installing the calico networking.."
#kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/32a765fd19ba45b387fdc5e3812c41fff47cfd55/Documentation/kube-flannel.yml
sleep 15s

echo "Checking If pods are running..."

kubectl get pods --all-namespaces
sleep 10s

echo " Tainting the master node to run work loads.."
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "Now, your running kubernetes cluster is ready..."
