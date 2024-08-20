#!/bin/bash

# Set permissions
chown -R unifi /var/lib/unifi /var/log/unifi /var/run/unifi
chown -R mongodb /var/lib/mongodb

# Start mongod service
echo "Starting mongod service..."
systemctl start mongod
echo "Done!"
# Start unifi service
echo "Starting unifi service..."
systemctl start unifi
echo "Done!"

tail -f /dev/null
