#!/bin/bash

sudo dpkg --configure -a
sudo apt-get update -y
sudo apt --fix-broken install -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release snapd jq docker.io docker-buildx

if [ -s /etc/docker/daemon.json ]; then sudo cat /etc/docker/daemon.json; else echo '{}'; fi \
    | jq 'if has("insecure-registries") then . else .+ {"insecure-registries": []} end' -- \
    | jq '."insecure-registries" |= (.+ ["localhost:32000"] | unique)' -- \
    | tee tmp.daemon.json
sudo mv tmp.daemon.json /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json
sudo chmod 600 /etc/docker/daemon.json

sudo systemctl restart docker

echo '10.255.32.133 hub' | sudo tee -a /etc/hosts
echo '10.255.32.134 spoke1' | sudo tee -a /etc/hosts
echo '10.255.32.110 spoke2' | sudo tee -a /etc/hosts

sudo ip route add 172.100.100.0/24 via 10.255.32.113

sudo snap install microk8s --classic --channel=1.24/stable
sudo snap alias microk8s.kubectl kubectl

sudo usermod -aG docker $USER
sudo usermod -aG microk8s $USER
sudo mkdir -p /home/$USER/.kube
sudo microk8s config > /home/$USER/.kube/config
sudo chown -f -R $USER /home/$USER/.kube

INTERFACE="eth0"
IP=$(ip -br -4 a | grep $INTERFACE | awk -F ' ' '{ print $3 }' | rev | cut -c 4- | rev)
sudo sed -i "s/#MOREIPS/IP.3 = $IP/g" /var/snap/microk8s/current/certs/csr.conf.template

sudo cat /var/snap/microk8s/current/certs/csr.conf.template
