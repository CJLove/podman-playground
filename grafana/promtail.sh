#!/bin/bash

DIR=$(basename $0)

# Public/private ports for syslog listener for promtail
SYSLOG_PORTS=1514:1514

# pihole user account (root)
ACCT=root

ACCT_UID=$(id -u $ACCT)
ACCT_GID=$(id -g $ACCT)

# Create directories under /root for state information
mkdir -p /root/promtail

echo "Creating promtail container..."
podman run -d --name promtail \
    -p $SYSLOG_PORTS \
 	-v /var/log:/var/log \
    -v /run/log/journal:/run/log/journal \
    -v /etc/machine-id:/etc/machine-id \
 	-v /$ACCT/promtail:/etc/promtail \
 	docker.io/grafana/promtail:2.4.0 -config.file=/etc/promtail/promtail-config.yml 
[ $? -ne 0 ] && { echo "Error creating container..."; exit 1; }

# echo "Enabling promtail service"
# cp $DIR/promtail.service /etc/systemd/system/promtail.service

# systemctl enable promtail.service
# systemctl start promtail.service

echo "promtail service running on port $SYSLOG_PORTS"
exit 0