#!/bin/bash
#
# Local build & publish helper. CI (.github/workflows/docker-publish.yml) is the
# primary path; use this for manual/local builds.
#
# Usage:
#   ./docker-build-publish.sh            # build the version in ./UNIFI_VERSION
#   ./docker-build-publish.sh 10.5.54    # build a specific version
set -euo pipefail

IMAGE="bisand/unifi-network-server"

# Version from the first argument, otherwise from the UNIFI_VERSION file.
UNIFI_VERSION="${1:-$(tr -d '[:space:]' < UNIFI_VERSION)}"

if [ -z "$UNIFI_VERSION" ]; then
  echo "ERROR: no UniFi version given and UNIFI_VERSION file is empty." >&2
  exit 1
fi

echo "Building ${IMAGE}:${UNIFI_VERSION} (linux/amd64)..."
docker build \
  --platform linux/amd64 \
  --build-arg "UNIFI_VERSION=${UNIFI_VERSION}" \
  -t "${IMAGE}:${UNIFI_VERSION}" \
  -t "${IMAGE}:latest" \
  .

# Login to Docker Hub (uncomment if not already logged in)
# echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

echo "Pushing ${IMAGE}:${UNIFI_VERSION} and :latest..."
docker push "${IMAGE}:${UNIFI_VERSION}"
docker push "${IMAGE}:latest"

echo "Done."
