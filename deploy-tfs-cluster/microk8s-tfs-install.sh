# Copyright 2024 David Araújo
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

INTERFACE="eth0"
IP=$(ip -br -4 a | grep $INTERFACE | awk -F ' ' '{ print $3 }' | rev | cut -c 4- | rev)

sudo dpkg --configure -a
sudo apt-get update -y
sudo apt --fix-broken install -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release snapd jq

sudo apt-get install -y docker.io docker-buildx


if [ -s /etc/docker/daemon.json ]; then sudo cat /etc/docker/daemon.json; else echo '{}'; fi \
    | jq 'if has("insecure-registries") then . else .+ {"insecure-registries": []} end' -- \
    | jq '."insecure-registries" |= (.+ ["localhost:32000"] | unique)' -- \
    | tee tmp.daemon.json
sudo mv tmp.daemon.json /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json
sudo chmod 600 /etc/docker/daemon.json

sudo systemctl restart docker

# Add nodes that may become part of the Microk8s cluster
## The controller where TFS will be installed must maintain the hostname 'hub'
echo '10.255.32.105 hub' | sudo tee -a /etc/hosts
echo '10.255.32.103 spoke1' | sudo tee -a /etc/hosts
echo '10.255.32.129 spoke2' | sudo tee -a /etc/hosts

sudo snap install microk8s --classic --channel=1.24/stable

sudo snap alias microk8s.kubectl kubectl

sudo usermod -aG docker $USER
sudo usermod -aG microk8s $USER

# Update certificates
sudo sed -i "s/#MOREIPS/IP.3 = $IP/g" /var/snap/microk8s/current/certs/csr.conf.template
sudo microk8s refresh-certs -e ca.crt

sudo mkdir -p /home/$USER/.kube
sudo microk8s config > /home/$USER/.kube/config
sudo chown -f -R $USER /home/$USER/.kube

# If this host is the controller, install TFS dependencies and clone TFS repo
if [ "hub" == $(cat /etc/hostname) ]; then
    mkdir /home/$USER/tfs-ctrl
    git clone https://labs.etsi.org/rep/tfs/controller.git /home/$USER/tfs-ctrl
    chown -f -R $USER /home/$USER/tfs-ctrl
else
    kubectl label nodes app.kubernetes.io/instance=cockroachdb
fi