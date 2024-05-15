#!/bin/bash

# How to make a simple wireguard VPN

sudo wg pubkey < ./wg-private-key
sudo wg set wg0 private-key ./wg-private-key

sudo ip link add wg0 type wireguard
sudo ip addr add 172.100.99.2/24 dev wg0
sudo ip link set wg0 up

sudo wg setconf wg0 ./wg-tun-conf