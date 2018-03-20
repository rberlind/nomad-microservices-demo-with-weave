#!/bin/bash

set -e

CONFIGDIR=/ops/shared/config

CONSULCONFIGDIR=/etc/consul.d
NOMADCONFIGDIR=/etc/nomad.d
HOME_DIR=ubuntu

# Wait for network
sleep 15

IP_ADDRESS=$(curl http://instance-data/latest/meta-data/local-ipv4)
DOCKER_BRIDGE_IP_ADDRESS=(`ifconfig docker0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`)
SERVER_COUNT=$1
REGION=$2
CLUSTER_TAG_VALUE=$3
TOKEN_FOR_NOMAD=$4
VAULT_URL=$5

# Consul
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/consul.json
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/consul.json
sed -i "s/REGION/$REGION/g" $CONFIGDIR/consul_upstart.conf
sed -i "s/CLUSTER_TAG_VALUE/$CLUSTER_TAG_VALUE/g" $CONFIGDIR/consul_upstart.conf
sudo cp $CONFIGDIR/consul.json $CONSULCONFIGDIR
sudo cp $CONFIGDIR/consul_upstart.conf /etc/init/consul.conf

sudo service consul start
sleep 10
export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500

# Nomad
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/nomad.hcl
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/nomad.hcl
sed -i "s@VAULT_URL@$VAULT_URL@g" $CONFIGDIR/nomad.hcl
sed -i "s/TOKEN_FOR_NOMAD/$TOKEN_FOR_NOMAD/g" $CONFIGDIR/nomad.hcl
sudo cp $CONFIGDIR/nomad.hcl $NOMADCONFIGDIR
sudo cp $CONFIGDIR/nomad_upstart.conf /etc/init/nomad.conf
export NOMAD_ADDR=http://$IP_ADDRESS:4646

# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

# Add Docker bridge network IP to /etc/resolv.conf (at the top)
echo "nameserver $DOCKER_BRIDGE_IP_ADDRESS" | sudo tee /etc/resolv.conf.new
cat /etc/resolv.conf | sudo tee --append /etc/resolv.conf.new
sudo mv /etc/resolv.conf.new /etc/resolv.conf

# Add search service.consul at bottom of /etc/resolv.conf
echo "search service.consul" | sudo tee --append /etc/resolv.conf

# Set env vars for tool CLIs
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export VAULT_ADDR=$VAULT_URL" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | sudo tee --append /home/$HOME_DIR/.bashrc

# Move weave and scope to /usr/bin
# and daemon.json to /etc/docker
sudo mv /home/ubuntu/weave /usr/bin/weave
sudo mv /home/ubuntu/scope /usr/bin/scope
sudo echo {\"cluster-store\":\"consul://127.0.0.1:8500\"} > /home/ubuntu/daemon.json
sudo mkdir -p /etc/docker
sudo mv /home/ubuntu/daemon.json /etc/docker/daemon.json

# Start Docker, Weave Net, and Weave Scope
sudo service docker restart
/usr/bin/weave launch --dns-domain="service.consul." --ipalloc-init consensus=2
sleep 30
/usr/bin/scope launch -weave.hostname scope.service.consul

# Create Docker Networks
for network in sockshop; do
  if [ $(docker network ls | grep $network | wc -l) -eq 0 ]
  then
    docker network create -d weave $network
  else
    echo docker network $network already created
  fi
done

# Copy Nomad jobs and scripts to desired locations
sudo cp /ops/shared/jobs/sockshop.nomad /home/ubuntu/sockshop.nomad
sudo chown -R $HOME_DIR:$HOME_DIR /home/$HOME_DIR/
sudo chmod  666 /home/ubuntu/*

# Start Nomad
sudo service nomad start
