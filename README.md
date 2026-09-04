# UniFi Network Server

UniFi Network Server running in docker.

This implementation is inspired by the work done by [Glenn R.](https://glennr.nl) and the UniFi Network Application [install script](https://glennr.nl/s/unifi-network-controller) from that site. 

> Note: This docker script is experimental and subject to change!

### Docker example

```bash
docker run -p 8080:8080 -p 8443:8443 -p 8880:8880 -p 8843:8843 -p 3478:3478/udp -p 10001:10001/udp -d bisand/unifi-network-server:latest
```

### Docker Compose example

#### Can also be used with docker swarm

```yml
version: '3.8'
services:
  network-server:
    image: bisand/unifi-network-server:latest
    ports:
      - 8080:8080
      - 8443:8443
      - 8880:8880
      - 8843:8843
      - 3478:3478/udp
      - 10001:10001/udp
    volumes:
      - unifi-data:/var/lib/unifi
      - mongodb-data:/var/lib/mongodb

volumes:
  unifi-data:
    driver: local
    # NFS mount for unifi data (Comment out and modify driver_opts if using NFS)
    # driver_opts:
    #   type: nfs
    #   o: nfsvers=4,addr=X.X.X.X,rw,noatime,nolock,rsize=32768,wsize=32768,tcp,timeo=14
    #   device: ":/srv/nfs/unifi/unifi-data"
  mongodb-data:
    driver: local
    # NFS mount for mongodb data (Comment out and modify driver_opts if using NFS)
    # driver_opts:
    #   type: nfs
    #   o: nfsvers=4,addr=X.X.X.X,rw,noatime,nolock,rsize=32768,wsize=32768,tcp,timeo=14
    #   device: ":/srv/nfs/unifi/mongodb-data"
```

### Build pipeline

`.github/workflows/docker-publish.yml` checks [glennr.nl](https://glennr.nl/s/unifi-network-controller)
nightly, builds and pushes `bisand/unifi-network-server:<version>` + `:latest`, then deploys by
committing the new image reference into the homelab GitOps repo.

**The cluster pulls; CI never reaches it.** The deploy step writes
`image: bisand/unifi-network-server:<version>@sha256:<digest>` into `stacks/unifi/unifi.yaml` in
`bisand/homelab`, and Flux reconciles it within ~5 minutes. Nothing inbound to the cluster, and no
kubeconfig exists in GitHub. The digest is what actually pins the rollout — the tag alongside it is
there so the manifest says which version it is running.

`UNIFI_VERSION` records the last version that was **both published and deployed successfully** — it is
committed only by the final step. Any run that fails leaves it untouched, so the next nightly run
retries; if the image for that version is already on Docker Hub, the rebuild is skipped and only the
deploy is retried.

| Setting | Kind | Required | Purpose |
| --- | --- | --- | --- |
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | secret | yes | Docker Hub push credentials |
| `HOMELAB_DEPLOY_KEY` | secret | yes | SSH private key with **write** access to `bisand/homelab`, so the deploy step can commit the image reference |

`HOMELAB_DEPLOY_KEY` is separate from the read-only key Flux uses to *read* that repo — this one
writes, and only to the one manifest. To create it:

```bash
ssh-keygen -t ed25519 -C "unifi-network-server CI" -f ./homelab-ci -N ""
```

Add `homelab-ci.pub` to `bisand/homelab` under Settings → Deploy keys with **Allow write access**
checked, add the private half as the `HOMELAB_DEPLOY_KEY` secret here, then delete both local files.
