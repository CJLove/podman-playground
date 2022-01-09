# Grafana loki log aggregator
There are separate deployments of `loki`/`grafana` containers in a `grafana-stack` pod running as non-root and `promtail` running separately as root.

## Loki and Grafana
The `grafana.sh` script can be run for a `grafana` user and the pod will be started running as that user. This will expose the loki and grafana ports as specified in the script.

The `loki-config.yml` should be copied into the `loki` directory prior to running.

## Promtail
The `promtail` script can be run to start the `promtail` container running as root. The `promtail-config.yml` file should be copied into the `/root/promtail` directory prior to running

