# Copyright 2024 David Araújo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "[!] Destroying existing Vagrant machines"
vagrant destroy -f --parallel

echo -e "\n[!] Removing destroyed hosts from known hosts"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.10"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.11"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.12"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.13"

echo -e "\n[+] Creating new hosts"
vagrant up

AVAILABLE=1
while [ $AVAILABLE -ne 0 ]
do
    ansible -o -i vagrant_inventory.yml -m ping nodes 2>&1 >/dev/null
    AVAILABLE=$?
done
echo -e "\n[!] Hosts ready, deploying configurations..."

ansible-playbook -i vagrant_inventory.yml ../playbook.yml