#!/bin/bash

# Public port for Registry
PORT=3005

# Public port for UI
UI_PORT=3006

# Registry user account
ACCT=registry

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

REG_CFG=$(dirname $0)/config.yml
UI_CFG=$(dirname $0)/ui_config.yml

# Copy repo's registry config if nothing is here
[ ! -f ./config.yml ] && { cp $REG_CFG .; }

# Copy ui config if nothing is here
[ ! -f ./ui_config.yml ] && { cp $UI_CFG .; }

[ ! -f reg_certs/registry.crt ] && { echo "Error: run create-certs.sh to generate registry.crt"; exit 1; }
[ ! -f reg_certs/registry.key ] && { echo "Error: run create-certs.sh to generate registry.key"; exit 1; }

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

# Cleanup of existing pod
podman pod stop registry > /dev/null 2>&1
podman pod rm registry > /dev/null 2>&1

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
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/registry..."; exit 1; }

echo "Setting owner/group on /home/$ACCT/data..."
podman unshare chown nobody:nobody /home/$ACCT/data
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/data..."; exit 1; }

echo "Creating pod..."
podman pod create --name registry -p $PORT:5000 -p $UI_PORT:8000
[ $? -ne 0 ] && { echo "Error creating pod..."; exit 1; }

echo "Creating registry container..."
podman run \
	-d \
	--pod registry \
	--name regsvr \
	-v /home/$ACCT/registry:/var/lib/registry \
	-v /home/$ACCT/reg_certs:/certs \
	-v /home/$ACCT/config.yml:/etc/docker/registry/config.yml \
	-e REGISTRY_STORAGE_DELETE_ENABLED=true \
	-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
	-e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
    --restart=always \
	registry:2.7

[ $? -ne 0 ] && { echo "Error creating regsvr container..."; exit 1; }

echo "Creating registry ui container..."
podman run \
	-d \
	--pod registry \
	--name regui \
	-v /home/$ACCT/ui_config.yml:/opt/config.yml \
	-v /home/$ACCT/data:/opt/data \
	-v /home/$ACCT/reg_certs/ca.crt:/etc/ssl/certs/ca-certificats.crt \
	-e TZ=America/Los_Angeles \
	--restart=always \
	quiq/docker-registry-ui

[ $? -ne 0 ] && { echo "Error creating regui container..."; exit 1; }


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

echo "Registry service running on port $PORT, Registry ui running on port $UI_PORT"
echo "Install reg_certs/ca.crt on all nodes"
exit 0