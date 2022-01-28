#!/bin/bash

# Installing k3sup tool
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

# Exporting  IPs and Hostnames
export SERVER_IP=x.x.x.x #Change this to the IP of the master node
export AGENT_IP=x.x.x.x #Change this to the IP of the agent node
export SERVER_USER=user #Change this to the user name of the master node
export AGENT_USER=user #Change this to the user name of the agent node

# Installing K3s on master node
k3sup install \
  --ip $SERVER_IP \
  --user $USER \
  --merge \
  --local-path $HOME/.kube/config \
  --context pi-k3s

# Installing K3s on worker node and connecting to master node
k3sup join \
  --ip $AGENT_IP \
  --server-ip $SERVER_IP \
  --user $AGENT_USER \
  --server-user $SERVER_USER

# You can install as many agents you want by repeating the above step

# Setting up kubectl context
export KUBECONFIG=$HOME/.kube/config
kubectl config use-context pi-k3s

echo "K3s setup Done!!!"

# Uninstalling and removing installed dependancies
sudo rm -r k3sup
sudo rm -r /usr/local/bin/k3sup
