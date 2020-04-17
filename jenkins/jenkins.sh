#!/bin/bash

# Public/private ports for Wiki-js and postgres
PORT=3003

# Jenkins host
JENKINS_IP=birch.local

# Jenkins user account
ACCT=jenkins

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# Validate that user account is set up for jenkins
echo "Validating account $ACCT..."
grep -i $ACCT /etc/subuid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-uids not setup for jenkins"; exit 1; }
grep -i $ACCT /etc/subgid
[ $? -eq 1 ] && { echo "Error: user $ACCT sub-gids not setup for jenkins"; exit 1; }

# Validate that home directory exists
[ ! -d /home/$ACCT ] && { echo "Error: /home/$ACCT doesn't exist for jenkins"; exit 1; }

echo "Setting owner/group on /home/$ACCT/..."
podman unshare chown $ACCT_UID:$ACCT_GID /home/$ACCT
[ $? -ne 0 ] && { echo "Error setting owner/group on /home/$ACCT..."; exit 1; }

echo "Creating pod..."
podman pod create --name jenkins -p $PORT:8080

echo "Starting jenkins container in pod..."
podman run -d --pod jenkins --name jenkins-ctrl \
	-e JENKINS_OPTS="--prefix=/jenkins" \
	-e JENKINS_IP="$JENKINS_IP" \
	-v /home/$ACCT:/var/jenkins/jenkins_home \
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
