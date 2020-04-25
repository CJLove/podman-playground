#!/bin/bash

# Public/private ports for Wiki-js and postgres
PORT=3003

# Jenkins host
JENKINS_IP=fir.local

# Jenkins user account
ACCT=jenkins

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

# Validate that user account is set up for jenkins
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for jenkins"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for jenkins"; exit 1; }

# Validate that home directory exists
[ ! -d /home/$ACCT/jenkins ] && { echo "Error: /home/$ACCT/jenkins doesn't exist for jenkins"; exit 1; }

# Inside the jenkins container processes run as user `jenkins`, uid 1000.
# Set file ownership to match that user to avoid permission issues
echo "Setting owner/group on /home/$ACCT/jenkins..."
podman unshare chown -R 1000:1000 /home/$ACCT/jenkins
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT/jenkins..."; exit 1; }

#podman unshare chmod 777 /home/$ACCT/jenkins

echo "Creating pod..."
podman pod create --name jenkins -p $PORT:8080 -p 50000:50000

echo "Starting jenkins container in pod..."
podman run -d --pod jenkins --name jenkins-ctrl \
	-e JENKINS_OPTS="--prefix=/jenkins" \
	-e JENKINS_IP="$JENKINS_IP" \
	-v /home/$ACCT/jenkins:/var/jenkins_home \
	-v /tmp:/tmp \
	jenkins/jenkins:lts

echo "Creating $HOME/.config/systemd/user..."
mkdir -p ~/.config/systemd/user

cd ~/.config/systemd/user
rm -f *.service

echo "Generating systemd unit files..."
podman generate systemd --name jenkins --files

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
echo "Jenkins service available on port $PORT"
exit 0
