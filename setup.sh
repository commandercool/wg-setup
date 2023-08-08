#!/bin/bash

# allow port-forwarding
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/10-wireguard.conf
sysctl -p /etc/sysctl.d/10-wireguard.conf
# install wireguard
apt update && sudo apt install wireguard iptables qrencode -y
# generate keys
cd /etc/wireguard/
wg genkey | tee server.key | wg pubkey > server.pub
wg genkey | tee client.key | wg pubkey > client.pub
# generate config
echo "[Interface]
Address = 10.1.1.1/24
ListenPort = 51820
PrivateKey = $(cat server.key)
PostUp = iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE

[Peer]
PublicKey = $(cat client.pub)
AllowedIPs = 10.1.1.2/32" > wg0.conf
# start wireguard
systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
# generate user config
# use qrencode -t ansiutf8 < client.conf
# to generate qr code
echo "[Interface]
PrivateKey = $(cat client.key)
Address = 10.1.1.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = $(cat server.pub)
AllowedIPs = 0.0.0.0/0
Endpoint = <fix address here>:51820" > client.conf
