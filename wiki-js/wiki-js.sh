#!/bin/bash

# Public/private ports for Wiki-js and postgres
WIKI_INT=3000
WIKI_EXT=3001
WIKI_PORTS=$WIKI_EXT:$WIKI_INT
PG_PORT=5432

# Wiki-js user account
ACCT=wiki

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# Validate that user account is set up for podman
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for podman"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for podman"; exit 1; }

# Validate that database directory exists
[ ! -d /home/$ACCT/db-data ] && { echo "Error: /home/$ACCT/db-data doesn't exist for postgres"; exit 1; }

echo "Setting owner/group on /home/$ACCT/db-data..."
podman unshare chown $ACCT_UID:$ACCT_GID /home/$ACCT/db-data
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/db-data..."; exi
t 1; }

echo "Creating pod..."
podman pod create --name wikijs -p $WIKI_PORTS -p $PG_PORT

echo "Starting postgres container in pod..."
podman run -d --pod wikijs --name db --hostname=db \
	-e POSTGRES_DB=wiki \
	-e POSTGRES_PASSWORD=wikijsrocks \
	-e POSTGRES_USER=wikijs \
	-v /home/$ACCT/db-data:/var/lib/postgresql/data postgres:11-alpine

echo "Starting wikijs container in pod..."
podman run -d --pod wikijs --name wiki \
	-e PORT=$WIKI_INT \
	-e DB_TYPE=postgres \
	-e DB_HOST=localhost \
	-e DB_PORT=$PG_PORT \
	-e DB_USER=wikijs \
	-e DB_PASS=wikijsrocks \
	-e DB_NAME=wiki \
	requarks/wiki:2

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name wikijs --files

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
echo "Wiki-js service available on port $WIKI_EXT"
exit 0
