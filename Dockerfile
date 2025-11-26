# Use a newer Ubuntu LTS to satisfy newer UniFi requirements
FROM ubuntu:24.04

# Prevent interactive prompts during apt/dpkg and provide TERM for scripts
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Allow opting out of running the interactive updater during the build.
# Default is true because we will select option 1 (Update the UniFi OS Server).
ARG RUN_UPDATE=true
ENV RUN_UPDATE=${RUN_UPDATE}

# Install minimal required packages (preserve existing install steps in your project)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg lsb-release unzip && \
    rm -rf /var/lib/apt/lists/*

# Copy installer files if you have them (uncomment/update if needed)
# COPY ./files /opt/files

# Run UniFi updater non-interactively when enabled.
# The wrapper checks common script locations and pipes '1' (Update UniFi OS Server) to the script.
# We use '|| true' so a non-zero exit won't break the build; this is safer for reproducible builds.
RUN if [ "${RUN_UPDATE}" = "true" ]; then \
      echo "RUN_UPDATE=true -> attempting to run UniFi updater and selecting menu option 1 (Update the UniFi OS Server)"; \
      # Try known possible updater locations; add more if needed
      if [ -x /usr/local/bin/unifi-update ]; then \
        printf '1\n' | /usr/local/bin/unifi-update || true; \
      elif [ -x /opt/unifi/install.sh ]; then \
        printf '1\n' | /opt/unifi/install.sh || true; \
      elif [ -x /opt/unifi/bin/upgrade.sh ]; then \
        printf '1\n' | /opt/unifi/bin/upgrade.sh || true; \
      elif [ -x /usr/bin/unifi-upgrade ]; then \
        printf '1\n' | /usr/bin/unifi-upgrade || true; \
      else \
        echo "No known UniFi updater script found; skipping updater. If your build invoked a different path, update the Dockerfile to point at it."; \
      fi; \
    else \
      echo "RUN_UPDATE is not true -> skipping UniFi updater"; \
    fi

# (keep your existing CMD/ENTRYPOINT)
CMD ["/bin/bash"]
