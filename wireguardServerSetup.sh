#!/bin/zsh
# Michael Oliver mcoliver.com
# ssh and configure wireguard
ssh ubuntu@$EXTERNALIP
sudo apt update -y && sudo apt install wireguard -y

sudo -i
mkdir -m 0700 /etc/wireguard/
cd /etc/wireguard/
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

#You will need the public key for your client setup
cat publickey

ETHINT="eth0"
SRVRIP="10.99.99.1"
ALLOWEDIPS="10.99.99.0/24"
PEERPUBKEY='GET THIS FROM YOUR WIREGUARD CLIENT'

tee  /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $SRVRIP/24
ListenPort = 41194
PrivateKey = $(cat privatekey)
PostUp = iptables -t nat -A POSTROUTING -o $ETHINT -j MASQUERADE; ip6tables -t nat -A POSTROUTING -o $ETHINT -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o $ETHINT -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o $ETHINT -j MASQUERADE

[Peer]
PublicKey = $PEERPUBKEY
AllowedIPs = $ALLOWEDIPS
EOF

ufw allow 41194/udp
ufw status
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.d/10-wireguard.conf
echo 'net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/sysctl.d/10-wireguard.conf
sysctl -p /etc/sysctl.d/10-wireguard.conf
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0
wg
ip a show wg0