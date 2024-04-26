#!/bin/bash

IP=${IP:-"172.100.99.1"}
PEERID=${PEERID:-"IoVGu4ADvm55R85SZhrRXUUq1s3kX9rRWMXzzoHi5H4="}
ALLOWED_RANGE=${ALLOWED_RANGE:-"172.100.0.0/16"}
ENDPOINT=${ENDPOINT:-"192.168.94.50:38485"}

wg genkey > /tmp/private
wg pubkey < /tmp/private

ip link add wg0 type wireguard
ip addr add $IP/24 dev wg0

wg set wg0 private-key /tmp/private

ip link set wg0 up

wg set wg0 peer $PEERID allowed-ips $ALLOWED_RANGE endpoint $ENDPOINT
