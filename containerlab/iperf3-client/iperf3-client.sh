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

#!/bin/bash
# Usage example: ./test-client.sh <IP> <PORT> <RESULTS DIRECTORY NAME>

touch /host/client.log

CONNECTION_STATUS=1
while [ $CONNECTION_STATUS -eq 1 ]
do
    # Give time for SRLinux node to stablish links
    sleep 30

    iperf3 -c 172.16.1.10 -p 8081 -t 60 -u --bidir --logfile /host/results.json -J
    CONNECTION_STATUS=$?
    echo "Connection status: $CONNECTION_STATUS" >> /host/client.log
done