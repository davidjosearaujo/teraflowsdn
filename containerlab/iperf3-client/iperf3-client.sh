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

until ping -c 1 172.16.1.10 >& /dev/null
do
    sleep 1
done

while [ 1 -eq 1]
do
    iperf3 -c 172.16.1.10 -p 8081 -t 60 -u --bidir --logfile /host/results.json -J
done