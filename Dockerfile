FROM ubuntu:24.04

# Prevent interactive prompts during apt/dpkg and provide TERM for scripts
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

ARG UNIFI_VERSION
ENV UNIFI_VERSION=${UNIFI_VERSION}

# Default to running the updater during build (you can opt out with --build-arg RUN_UPDATE=false)
ARG RUN_UPDATE=true
ENV RUN_UPDATE=${RUN_UPDATE}

# Install dependencies (add expect so we can interact with installer menus in a PTY)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      openssh-server \
      expect \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and install UniFi (use expect when RUN_UPDATE=true to provide menu choice 1)
RUN wget https://get.glennr.nl/unifi/install/unifi-${UNIFI_VERSION}.sh -O unifi-${UNIFI_VERSION}.sh && \
    chmod +x unifi-${UNIFI_VERSION}.sh && \
    if [ "${RUN_UPDATE}" = "true" ]; then \
      echo "RUN_UPDATE=true -> using expect to select menu option 1 (Update the UniFi OS Server)"; \
      expect <<EOF
set timeout -1
spawn ./unifi-${UNIFI_VERSION}.sh --skip --local-install
# When the installer prints the menu, send "1" followed by carriage return.
# Use a pattern match for the menu prompt; if not matched, EOF will end the expect run.
expect {
  "What would you like to perform?" { send "1\r"; exp_continue }
  eof
}
EOF
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
    rm -rf /var/lib/apt/lists/*

# Expose TCP and UDP ports required by UniFi Controller
EXPOSE 8080 8443 8880 8843
EXPOSE 3478/udp 10001/udp 1900/udp

# Make sure service mongod and unifi are enabled (systemctl wrapper is earlier in original Dockerfile)
RUN (systemctl enable mongod || true) && \
    systemctl enable unifi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
