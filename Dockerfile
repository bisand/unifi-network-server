
FROM ubuntu:noble 

ARG UNIFI_VERSION=8.3.32
ENV UNIFI_VERSION=${UNIFI_VERSION}

# Install dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y ca-certificates \
    wget \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and install alternate systemctl
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/local/bin/systemctl
RUN chmod +x /usr/local/bin/systemctl

# Download and install UniFi
RUN wget https://get.glennr.nl/unifi/install/unifi-${UNIFI_VERSION}.sh && \
    chmod +x unifi-${UNIFI_VERSION}.sh && \
    ./unifi-${UNIFI_VERSION}.sh \
    --skip \
    --local-install

# Clean up
RUN rm -rf unifi-${UNIFI_VERSION}.sh && \
    rm -rf unifi_sysvinit_all.deb && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose TCP ports
EXPOSE 8080 8443 8880 8843
# Expose UDP ports
EXPOSE 3478/udp 10001/udp 1900/udp

# Make sure service mongod and unifi are started
RUN systemctl enable mongod && \
    systemctl enable unifi

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start docker with just an infinite pause
CMD ["/entrypoint.sh"]
