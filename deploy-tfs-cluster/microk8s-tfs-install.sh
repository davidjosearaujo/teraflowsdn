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

apt-get update -y
apt-get dist-upgrade -y

apt-get install -y ca-certificates curl gnupg lsb-release snapd jq

apt-get install -y docker.io docker-buildx

if [ -s /etc/docker/daemon.json ]; then cat /etc/docker/daemon.json; else echo '{}'; fi \
    | jq 'if has("insecure-registries") then . else .+ {"insecure-registries": []} end' -- \
    | jq '."insecure-registries" |= (.+ ["localhost:32000"] | unique)' -- \
    | tee tmp.daemon.json
mv tmp.daemon.json /etc/docker/daemon.json
chown root:root /etc/docker/daemon.json
chmod 600 /etc/docker/daemon.json

systemctl restart docker

# Add nodes that may become part of the Microk8s cluster
## The controller where TFS will be installed must maintain the hostname 'controller'
echo '192.168.56.2 controller' | tee -a /etc/hosts
echo '192.168.56.3 spoke1' | tee -a /etc/hosts
echo '192.168.56.4 spoke2' | tee -a /etc/hosts

snap install microk8s --classic --channel=1.24/stable

snap alias microk8s.kubectl kubectl

usermod -aG docker $USER
usermod -aG microk8s $USER

newgrp microk8s
newgrp docker

mkdir -p $HOME/.kube
microk8s config > $HOME/.kube/config
chown -f -R $USER $HOME/.kube

newgrp microk8s

microk8s start

# If this host is the controller, install TFS dependencies and clone TFS repo
if [ "contoller" == $(cat /etc/hostname) ]; then
    microk8s.enable community
    microk8s.enable dns helm3 hostpath-storage ingress registry prometheus metrics-server linkerd
    snap alias microk8s.helm3 helm3
    snap alias microk8s.linkerd linkerd
    linkerd check

    git clone https://labs.etsi.org/rep/tfs/controller.git
fi