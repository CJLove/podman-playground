#!/bin/bash

# Public port for Nginx
PORT=3004

# NGINX user account
ACCT=nginx

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

# Validate that user account is set up for podman
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for podman"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for podman"; exit 1; }

# Validate that directory with web content exists
[ ! -d /home/$ACCT/www ] && { echo "Error: /home/$ACCT/www doesn't exist for web content"; exit 1; } 

echo "Setting owner/group on /home/$ACCT/www..."
podman unshare chown $ACCT_UID:$ACCT_GID /home/$ACCT/www
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/www..."; exit 1; }

echo "Creating pod..."
podman pod create --name nginx -p $PORT:80
[ $? -ne 0 ] && { echo "Error creating pod..."; exit 1; }

echo "Creating nginx container..."
podman run \
	-d \
	--pod nginx \
	--name http \
	-v /home/$ACCT/www:/usr/share/nginx/html/ \
	nginx:latest

[ $? -ne 0 ] && { echo "Error creating container..."; exit 1; }

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name nginx --files
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

echo "Nginx service running on port $PORT"
exit 0

