# Multi-architecture Docker registry running under podman

This script creates an insecure private registry

## Example
```
[registry@fir ~]$ ~love/Development/podman-playground/registry/registry.sh 
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1006/bus
Validating account registry...
registry:427680:65536
registry:427680:65536
Setting owner/group on /home/registry/registry...
Creating pod...
1274e1444ef341ca32151db0c3b13eb4591f16cdf51bd7ea56228612953adca2
Creating  container...
bf6653b46a1c544c3a8a98eecc98ca491c7de418bee9a3e5467327d9b11035b5
Creating /home/registry/.config/systemd/user...
Generating systemd unit files...
/home/registry/.config/systemd/user/pod-registry.service
/home/registry/.config/systemd/user/container-regsvr.service
    Fixing target in container-regsvr.service...
    Fixing target in pod-registry.service...
Reloading systemd...
Enabling systemd services...
    Enabling container-regsvr.service...
Created symlink /home/registry/.config/systemd/user/default.target.wants/container-regsvr.service → /home/registry/.config/systemd/user/container-regsvr.service.
    Enabling pod-registry.service...
Created symlink /home/registry/.config/systemd/user/default.target.wants/pod-registry.service → /home/registry/.config/systemd/user/pod-registry.service.
/home/registry
Registry service running on port 3005

```

## Updating podman config
```
> sudo vi /etc/containers/registry.conf
```

Update podman config (Version 1 format)
```
[registries.insecure]
registries = ['fir.local:3005']
```

## Push sample image on x86-64
```
# Pull image from docker.io
> podman pull hello-world
# Re-tag for private registry
> podman tag docker.io/library/hello-world fir.local:3005/hello-world
# Push to private registry
> podman push fir.local:3005/hello-world
# Remove local image
> podman rmi fir.local:3005/hello-world
# Run image from private registry
> podman run --rm fir.local:3005/hello-world
```

## Push sample image on arm
```
# Pull arm64v8 image from docker.io
> podman pull arm64v8/hello-world
# Re-tag for private registry
> podman tag docker.io/arm64v8/hello-world fir.local:3005/arm64v8/hello-world
# Push to private registry
> podman push fir.local:3005/arm64v8/hello-world
# Remove local image
> podman rmi fir.local:3005/arm64v8/hello-world
# Run image from private registry
> 
```

## References
- https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/deploying-multi-architecture-docker-registry (Note that the registry image is available for multiple architectures as of 2.7.x)
- https://computingforgeeks.com/create-docker-container-registry-with-podman-letsencrypt/
- https://registry.hub.docker.com/_/registry/
