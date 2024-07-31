sudo containerlab deploy --reconfigure
docker exec -d clab-tfs-scenario-client1 bash /host/iperf3-server.sh
docker exec -d clab-tfs-scenario-client2 bash /host/iperf3-client.sh