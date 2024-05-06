# How to make a simple wireguard VPN

```bash
sudo wg genkey > /tmp/private
sudo wg pubkey < /tmp/private

sudo ip link add wg0 type wireguard
sudo ip addr add 172.100.99.2/24 dev wg0

sudo wg set wg0 private-key /tmp/private

sudo ip link set wg0 up

sudo wg set wg0 peer $PEERID allowed-ips 172.100.0.0/16 endpoint $ENDPOINT
```bash