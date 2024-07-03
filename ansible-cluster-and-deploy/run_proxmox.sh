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

ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.61"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.137"
ssh-keygen -f "/home/davidjosearaujo/.ssh/known_hosts" -R "192.168.56.75"

AVAILABLE=1
while [ $AVAILABLE -ne 0 ]
do
    ansible -o -i proxmox_inventory.yml -m ping nodes 2>&1 >/dev/null
    AVAILABLE=$?
done

ansible-playbook -i proxmox_inventory.yml playbook.yml