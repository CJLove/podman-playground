# Simple Nginx Service via Podman

Service runs as user 'nginx' on port 3004.

Content from /home/nginx/www is served by nginx

The `nginx.sh` script will deploy the pod and its container and then generate Systemd unit files for each.  These files are installed in `/home/nginx/.config/systemd/user` and enabled via `systemctl --user enable ...`

## Example

```bash
[nginx@birch nginx]$ ./nginx.sh 
Validating account nginx...
nginx:231072:65536
nginx:231072:65536
Setting owner/group on /home/nginx/www...
Creating pod...
57a475d9db33e0d815e11c92c6938590c6f3b7ed32ac97f5883886cbab0b49c8
Creating nginx container...
bbe0b072ec560fc256fe1f2e43783c71348b78b62ff1fb7001d431db4ce045b6
Creating /home/nginx/.config/systemd/user...
Generating systemd unit files...
/home/nginx/.config/systemd/user/pod-nginx.service
/home/nginx/.config/systemd/user/container-http.service
    Fixing target in container-http.service...
    Fixing target in pod-nginx.service...
Reloading systemd...
Enabling systemd services...
    Enabling container-http.service...
Created symlink /home/nginx/.config/systemd/user/default.target.wants/container-http.service → /home/nginx/.config/systemd/user/container-http.service.
    Enabling pod-nginx.service...
Created symlink /home/nginx/.config/systemd/user/default.target.wants/pod-nginx.service → /home/nginx/.config/systemd/user/pod-nginx.service.
/home/love/Development/podman/nginx
Nginx service running on port 3004

[nginx@birch nginx]$ podman pod list
POD ID         NAME    STATUS    CREATED          # OF CONTAINERS   INFRA ID
57a475d9db33   nginx   Running   14 seconds ago   2                 62bea1b76333

[nginx@birch ~]$ curl http://birch:3004
Welcome to birch!
```
