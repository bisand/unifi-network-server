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