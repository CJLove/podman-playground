#!/bin/bash

# Public/private ports for loki and grafana
LOKI_INT=3100
LOKI_EXT=3008
LOKI_PORTS=$LOKI_EXT:$LOKI_INT
GRAF_INT=3000
GRAF_EXT=3009
GRAF_PORTS=$GRAF_EXT:$GRAF_INT

# Grafana user account
ACCT=grafana

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# If necessary, set XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS to fix `systemctl --user`
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

# Validate that user account is set up for podman
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for podman"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for podman"; exit 1; }

cd /home/$ACCT
mkdir -p grafana
mkdir -p loki
mkdir -p promtail

for f in loki promtail
do

	echo "Setting owner/group on /home/$ACCT/$f..."
	podman unshare chown -R $ACCT_UID:$ACCT_GID /home/$ACCT/$f
	[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/$f..."; exit 1; }
done

echo "Creating pod..."
podman pod create --name grafana-stack -p $LOKI_PORTS -p $GRAF_PORTS

echo "Starting loki container in pod..."
podman run -d --pod grafana-stack --name loki \
	-v /home/$ACCT/loki:/etc/loki:Z \
	docker.io/grafana/loki:2.4.0 -config.file=/etc/loki/loki-config.yml

# echo "Starting promtail container in pod..."
# podman run -d --pod grafana-stack --name promtail \
# 	-v /var/log:/var/log \
# 	-v /home/$ACCT/promtail:/etc/promtail:Z \
# 	docker.io/grafana/promtail:2.4.0 -config.file=/etc/promtail/promtail-config.yml 

echo "Starting grafana container in pod..."
podman run -d --pod grafana-stack --name grafana \
	-v /home/$ACCT/grafana:/var/lib/grafana:Z \
	docker.io/grafana/grafana:latest

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name grafana-stack --files

for f in *.service
do
	echo "    Fixing target in $f..."
	sed -i 's/multi-user.target //g' $f
done

echo "Reloading systemd..."
systemctl --user daemon-reload

echo "Enabling systemd services..."
for f in *.service
do
	echo "    Enabling $f..."
	systemctl --user enable $f
	[ $? -ne 0 ] && { echo "Error enabling service $f..."; exit 1; }
done

cd -
echo "Grafana service available on ports $LOKI_EXT, $GRAF_EXT"
exit 0
