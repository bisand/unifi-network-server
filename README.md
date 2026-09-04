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
committing the new image reference into a GitOps repository.

**The cluster pulls; CI never reaches it.** The deploy step writes
`image: bisand/unifi-network-server:<version>@sha256:<digest>` into a manifest in that repository,
and [Flux](https://fluxcd.io) reconciles it within ~5 minutes. Nothing inbound to the cluster, and no
kubeconfig exists in GitHub. The digest is what actually pins the rollout — the tag alongside it is
there so the manifest says which version it is running.

`UNIFI_VERSION` records the last version that was **both published and deployed successfully** — it is
committed only by the final step. Any run that fails leaves it untouched, so the next nightly run
retries; if the image for that version is already on Docker Hub, the rebuild is skipped and only the
deploy is retried.

This repository is public, so the deploy target is configured entirely through secrets. Nothing about
the private infrastructure — its repository, branch, layout or addresses — belongs in these files or
in the run logs they produce.

| Setting | Kind | Purpose |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | secret | Docker Hub push credentials |
| `HOMELAB_DEPLOY_KEY` | secret | SSH private key with **write** access to the GitOps repository |
| `DEPLOY_REPO` | secret | Clone URL of that repository, e.g. `ssh://git@github.com/<owner>/<repo>.git` |
| `DEPLOY_BRANCH` | secret | Branch Flux tracks |
| `DEPLOY_MANIFEST` | secret | Path within that repository to the manifest holding the image line |

The deploy key is separate from, and should not be reused from, the read-only key Flux uses to *read*
that repository — this one writes. To create it:

```bash
ssh-keygen -t ed25519 -C "unifi-network-server CI" -f ./ci-deploy -N ""
```

Add `ci-deploy.pub` to the GitOps repository under Settings → Deploy keys with **Allow write access**
checked, add the private half as the `HOMELAB_DEPLOY_KEY` secret here, then delete both local files.
