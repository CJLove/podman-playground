#!/bin/bash

# Public/private ports for Uptime-kuma monitoring/dashboard
PORT=3010

# Uptime-kuma user account
ACCT=dash

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

# Validate that user account is set up for dash
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for dash"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for dash"; exit 1; }

# Validate that home directory exists
[ ! -d /home/$ACCT/data ] && { echo "Error: /home/$ACCT/data doesn't exist for dash"; exit 1; }

# Inside the jenkins container processes run as user `jenkins`, uid 1000.
# Set file ownership to match that user to avoid permission issues
echo "Setting owner/group on /home/$ACCT/data..."
podman unshare chown -R $ACCT_UID:$ACCT_GID /home/$ACCT/data
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/data..."; exit 1; }

echo "Creating pod..."
podman pod create --name uptime-kuma -p $PORT:3001

echo "Starting uptime-kuma container in pod..."
podman run -d --pod uptime-kuma --name uptime \
	-v /home/$ACCT/data:/app/data \
	louislam/uptime-kuma:1

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name uptime-kuma --files

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
echo "Uptime-kuma service available on port $PORT"
exit 0
