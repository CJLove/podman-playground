# PiHole

This script sets up to run containerized pihole as root using podman

## Notes
- `systemd-resolved` listens on port 53 by default, so do the following to disable:
```
$ sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
$ sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
$ sudo systemctl restart systemd-resolved
```
- Any other DNS service (e.g. `dnsmasq`) also needs to be available so nothing is listening on tcp/udp port 53.
- edit the script as desired for the port for the pihole web interface