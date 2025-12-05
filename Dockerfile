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
# Use a single RUN that writes a small expect script via printf to avoid Dockerfile heredoc parsing issues.
RUN wget https://get.glennr.nl/unifi/install/unifi-${UNIFI_VERSION}.sh -O unifi-${UNIFI_VERSION}.sh && \
    chmod +x unifi-${UNIFI_VERSION}.sh && \
    if [ "${RUN_UPDATE}" = "true" ]; then \
        echo "RUN_UPDATE=true -> creating expect script to select menu option 1 (Update the UniFi OS Server)"; \
        # Create the expect script without using a Dockerfile heredoc (printf ensures all content is part of this RUN)
        printf '%s\n' '#!/usr/bin/expect -f' \
            'set timeout -1' \
            "spawn ./unifi-${UNIFI_VERSION}.sh --skip --local-install" \
            'expect {' \
            '  "What would you like to perform?" { send "1\r"; exp_continue }' \
            '  eof' \
            '}' > /tmp/unifi_expect && \
        chmod +x /tmp/unifi_expect && \
        expect -f /tmp/unifi_expect || true; \
    else \
        echo "RUN_UPDATE is not true -> running installer without automated menu selection"; \
        ./unifi-${UNIFI_VERSION}.sh --skip --local-install; \
    fi

# Clean up installer and unneeded packages to keep image smaller
RUN rm -rf unifi-${UNIFI_VERSION}.sh && \
    rm -rf unifi_sysvinit_all.deb && \
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
RUN chmod +x /entrypoint.sh

# Start docker with entrypoint
CMD ["/entrypoint.sh"]
