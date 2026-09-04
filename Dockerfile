FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

ARG UNIFI_VERSION
ENV UNIFI_VERSION=${UNIFI_VERSION}

ARG RUN_UPDATE=true
ENV RUN_UPDATE=${RUN_UPDATE}

# Install dependencies (include expect so we can drive a PTY-based installer)
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      iproute2 \
      wget \
      openssh-server \
      expect \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and install alternate systemctl
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/local/bin/systemctl
RUN chmod +x /usr/local/bin/systemctl

# Download and install UniFi.
# install-unifi.sh downloads the installer (with retries), drives its menu via
# expect and then VERIFIES the result, so a failed install fails the build instead
# of silently publishing a broken image.
COPY install-unifi.sh /tmp/install-unifi.sh
RUN chmod +x /tmp/install-unifi.sh && /tmp/install-unifi.sh && rm -f /tmp/install-unifi.sh

# Clean up installer and unneeded packages to keep image smaller
RUN rm -rf unifi-${UNIFI_VERSION}.sh unifi_sysvinit_all.deb && \
    apt-get remove -y wget expect && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/unifi_expect

# Expose TCP ports
EXPOSE 8080 8443 8880 8843
# Expose UDP ports
EXPOSE 3478/udp 10001/udp 1900/udp

# Make sure service mongod and unifi are started
RUN (systemctl enable mongod || true) && \
    systemctl enable unifi

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && [ -x /entrypoint.sh ]

# Start docker with entrypoint
CMD ["/entrypoint.sh"]
