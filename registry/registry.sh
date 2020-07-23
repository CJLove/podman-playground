#!/bin/bash

# Public port for Registry
PORT=3005

# Registry user account
ACCT=registry

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

# Validate that directory with web content exists
[ ! -d /home/$ACCT/registry ] && { echo "Error: /home/$ACCT/registry doesn't exist for registry content"; exit 1; } 

echo "Setting owner/group on /home/$ACCT/registry..."
podman unshare chown $ACCT_UID:$ACCT_GID /home/$ACCT/registry
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/Source..."; exit 1; }

echo "Creating pod..."
podman pod create --name registry -p $PORT:5000
[ $? -ne 0 ] && { echo "Error creating pod..."; exit 1; }

echo "Creating  container..."
podman run \
	-d \
	--pod registry \
	--name regsvr \
	-v /home/$ACCT/registry:/var/lib/registry \
    --restart=always \
	registry:2.7

[ $? -ne 0 ] && { echo "Error creating container..."; exit 1; }

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name registry --files
[ $? -ne 0 ] && { echo "Error generating systemd unit files..."; exit 1; }

for f in *.service
do
	echo "    Fixing target in $f..."
	sed -i 's/multi-user.target //g' $f
done

echo "Reloading systemd..."
systemctl --user daemon-reload
[ $? -ne 0 ] && { echo "Error reloading systemd..."; exit 1; }

echo "Enabling systemd services..."
for f in *.service
do
	echo "    Enabling $f..."
	systemctl --user enable $f
	[ $? -ne 0 ] && { echo "Error enabling service $f..."; exit 1; }
done

cd -

echo "Registry service running on port $PORT"
exit 0