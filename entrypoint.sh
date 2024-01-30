#!/bin/bash

# Start mongod service
echo "Starting mongod service..."
systemctl start mongod
echo "Done!"
# Start unifi service
echo "Starting unifi service..."
systemctl start unifi
echo "Done!"

tail -f /dev/null
