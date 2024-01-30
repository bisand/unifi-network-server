FROM ubuntu:23.10

ARG UNIFI_VERSION=8.0.28
ENV UNIFI_VERSION=${UNIFI_VERSION}

# Enable apt repositories.
RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

# Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    systemctl systemd-sysv \
    ca-certificates \
    wget \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/* \
    && rm -f /lib/systemd/system/plymouth* \
    && rm -f /lib/systemd/system/systemd-update-utmp*

VOLUME [ "/sys/fs/cgroup" ]

# Download and install UniFi
RUN wget https://get.glennr.nl/unifi/install/unifi-${UNIFI_VERSION}.sh && \
    chmod +x unifi-${UNIFI_VERSION}.sh && \
    ./unifi-${UNIFI_VERSION}.sh \
    --skip \
    --local-install \
    --custom-url https://dl.ui.com/unifi/${UNIFI_VERSION}/unifi_sysvinit_all.deb

# Clean up
RUN rm -rf unifi-${UNIFI_VERSION}.sh && \
    rm -rf unifi_sysvinit_all.deb && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose ports
EXPOSE 8080 8443 8880 8843

# Start UniFi
CMD ["java", "-jar", "/usr/lib/unifi/lib/ace.jar", "start"]
