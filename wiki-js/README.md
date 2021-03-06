# Wiki-js Service via Podman

Service runs as user 'wiki' on port 3001.

Wiki data is stored in Postgres in /home/wiki/db-data.

The `wiki-js.sh` script will deploy the pod and its containers and then generate Systemd unit files for each.  These files are installed in `/home/wiki/.config/systemd/user` and enabled via `systemctl --user enable ...`

## Example

```bash
[wiki@birch wiki-js]$ ./wiki-js.sh 
Validating account wiki...
wiki:165536:65536
wiki:165536:65536
Setting owner/group on /home/wiki/db-data...
Creating pod...
cecbb8a1c612b9e584c5f7ad52d079544dbe82c31da886a934f7e7dd1caa2cd9
Starting postgres container in pod...
0b4df0eaedace67e08e6565598700a752a9bc96bd1d0820695ccf52e303307e0
Starting wikijs container in pod...
008ae493362ee9e8940c4e66af516d8dfe2c739c8562f6a1385799710f8d5068
Creating /home/wiki/.config/systemd/user...
Generating systemd unit files...
/home/wiki/.config/systemd/user/pod-wikijs.service
/home/wiki/.config/systemd/user/container-wiki.service
/home/wiki/.config/systemd/user/container-db.service
    Fixing target in container-db.service...
    Fixing target in container-wiki.service...
    Fixing target in pod-wikijs.service...
Reloading systemd...
Enabling systemd services...
    Enabling container-db.service...
Created symlink /home/wiki/.config/systemd/user/default.target.wants/container-db.service → /home/wiki/.config/systemd/user/container-db.service.
    Enabling container-wiki.service...
Created symlink /home/wiki/.config/systemd/user/default.target.wants/container-wiki.service → /home/wiki/.config/systemd/user/container-wiki.service.
    Enabling pod-wikijs.service...
Created symlink /home/wiki/.config/systemd/user/default.target.wants/pod-wikijs.service → /home/wiki/.config/systemd/user/pod-wikijs.service.
/home/love/Development/podman-playground/wiki-js
Wiki-js service available on port 
[wiki@birch wiki-js]$ podman pod list
POD ID         NAME     STATUS    CREATED          # OF CONTAINERS   INFRA ID
cecbb8a1c612   wikijs   Running   10 seconds ago   3                 3906ec524b8a
[wiki@birch wiki-js]$
```
