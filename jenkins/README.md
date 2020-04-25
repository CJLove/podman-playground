# Jenkins Service via Podman

Service runs as user 'jenkins' on port 3003.

Jenkins data is stored under /home/jenkins

The `jenkins.sh` script will deploy the pod and the Jenkins container and then generate Systemd unit files for each.  These files are installed in `/home/jenkins/.config/systemd/user` and enabled via `systemctl --user enable ...`

## Caveats
- In the Jenkins image, everything runs as the `jenkins` user (1000), hence the need to do `podman unshare chown -R 1000:1000 /home/jenkins/jenkins` so it has write permissions to /var/jenkins_home inside of the container
- While it appears that mDNS lookups will fail inside podman containers, entries from `/etc/hosts` on the host are mapped to `/etc/hosts` inside of the container, hosts entries can be used to resolve IP addresses which wouldn't otherwise resolve through regular DNS lookups.
- The Jenkins Docker-related plugins and `docker` agent in Jenkinsfile doesn't appear to work.  

## Example
```bash

[jenkins@birch jenkins]$ ./jenkins.sh 
Validating account jenkins...
jenkins:362144:65536
jenkins:362144:65536
Setting owner/group on /home/jenkins/...
Creating pod...
8610abd7c237a602c5c95bbeeb363a4e71c64691fe8b6c9b089bdd9a3fa9f360
Starting jenkins container in pod...
a00f812baa67526f369f07f57141c573a5ea45dc761d41ad9f7df2e9aa741820
Creating /home/jenkins/.config/systemd/user...
Generating systemd unit files...
/home/jenkins/.config/systemd/user/pod-jenkins.service
/home/jenkins/.config/systemd/user/container-jenkins-ctrl.service
    Fixing target in container-jenkins-ctrl.service...
    Fixing target in pod-jenkins.service...
Reloading systemd...
Enabling systemd services...
    Enabling container-jenkins-ctrl.service...
    Enabling pod-jenkins.service...
/home/love/Development/podman-playground/jenkins
Jenkins service available on port 3003
[jenkins@birch jenkins]$ podman pod list
POD ID         NAME      STATUS    CREATED          # OF CONTAINERS   INFRA ID
8610abd7c237   jenkins   Running   11 minutes ago   2                 ec8db966bfa8

```
