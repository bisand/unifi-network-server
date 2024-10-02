#!/bin/bash

# Read the version from the UNIFI_VERSION file
UNIFI_VERSION=$(cat UNIFI_VERSION)

# Build the Docker image with the version tag and pass the version as a build argument
docker build --build-arg UNIFI_VERSION=$UNIFI_VERSION -t bisand/unifi-network-server:$UNIFI_VERSION .

# Tag the Docker image with the 'latest' tag
docker tag bisand/unifi-network-server:$UNIFI_VERSION bisand/unifi-network-server:latest

# Login to Docker Hub
# echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Push the Docker image with the version tag to Docker Hub
docker push bisand/unifi-network-server:$UNIFI_VERSION

# Push the Docker image with the 'latest' tag to Docker Hub
docker push bisand/unifi-network-server:latest