#!/bin/bash

# Public and DNS ports for pihole
PORT=3007
DNS=53

# pihole user account (root)
ACCT=root

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# If necessary, set XDG_RUNTIME_DIR to fix `systemctl --user`
grep -q XDG_RUNTIME_DIR $HOME/.bash_profile
if [ $? -ne 0 ]; then
	echo "XDG_RUNTIME_DIR=/run/user/`id -u`" >> $HOME/.bash_profile
	export XDG_RUNTIME_DIR=/run/user/`id -u`
fi
grep -q DBUS_SESSION_BUS_ADDRESS $HOME/.bash_profile
if [ $? -ne 0 ]; then
	echo "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u`/bus"
	export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u`/bus
fi

# Make sure web password has been supplied
[ -z "$WEBPASSWD" ] && { echo "Need to set WEBPASSWD environment variable"; exit 1; }

# Create directories under /root for state information
mkdir -p /root/pihole /root/dnsmasq

echo "Creating pihole container..."
podman run -d \
	--name=pihole \
	--hostname fir.love.io \
	-e TZ=America/Los_Angeles \
	-e WEBPASSWORD=$WEBPASSWORD \
	-e SERVERIP=127.0.0.1 \
	--dns=127.0.0.1 --dns=208.67.222.222 --dns=208.67.220.220 \
	-v /$ACCT/pihole:/etc/pihole:z \
	-v /$ACCT/dnsmasq:/etc/dnsmasq.d:z \
	-p $PORT:80 \
	-p $DNS:53/tcp \
	-p $DNS:53/udp \
	--restart=unless-stopped \
	pihole/pihole:latest
[ $? -ne 0 ] && { echo "Error creating container..."; exit 1; }

cp pihole.service /etc/systemd/system/pihole.service

echo "enabling pihole service"
systemctl enable pihole.service
systemctl start pihole.service


echo "pihole service running on port $PORT"
exit 0

