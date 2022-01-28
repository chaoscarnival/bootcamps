#!/bin/bash

# Exporting  IPs and Hostnames
export SERVER_IP=x.x.x.x #Change this to the IP of the master node
export AGENT_IP=x.x.x.x #Change this to the IP of the agent node
export SERVER_USER=user #Change this to the user name of the master node
export AGENT_USER=user #Change this to the user name of the agent node

# Uninstall master node
ssh $SERVER_USER@$SERVER_IP /usr/local/bin/k3s-uninstall.sh > /dev/null

# Uninstall worker node
# If you have more than one agent installed, copy the below commands and run them for all the agents.
ssh $AGENT_USER@$AGENT_IP /usr/local/bin/k3s-agent-uninstall.sh > /dev/null

# Remove the config for the cluster
kubectl config unset contexts.pi-k3s
kubectl config unset clusters.pi-k3s
kubectl config unset users.pi-k3s
