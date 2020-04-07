#!/bin/bash

# Public port for Opengrok
PORT=3002

# Opengrok user account
ACCT=opengrok

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# Validate that user account is set up for podman
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for podman"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for podman"; exit 1; }

# Validate that directory with web content exists
[ ! -d /home/$ACCT/Source ] && { echo "Error: /home/$ACCT/Source doesn't exist for web content"; exit 1; } 

echo "Setting owner/group on /home/$ACCT/Source..."
podman unshare chown $ACCT_UID:$ACCT_GID /home/$ACCT/Source
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/Source..."; exit 1; }

echo "Creating pod..."
podman pod create --name opengrok -p $PORT:8080
[ $? -ne 0 ] && { echo "Error creating pod..."; exit 1; }

echo "Creating indexer container..."
podman run \
	-d \
	--pod opengrok \
	--name indexer \
	-e REINDEX=0 \
	-v /home/$ACCT/Source:/opengrok/src \
	opengrok/docker:latest

[ $? -ne 0 ] && { echo "Error creating container..."; exit 1; }

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name opengrok --files
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

echo "Opengrok service running on port $PORT"
exit 0

