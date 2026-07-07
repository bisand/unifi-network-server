#!/bin/bash
#
# Container entrypoint: start MongoDB + UniFi (via the systemctl replacement),
# surface their logs to `docker logs`, and stay in the foreground so the
# container does not exit.

# Bind-mounted data dirs can start out empty — make sure they exist before chown.
mkdir -p /var/lib/unifi /var/log/unifi /var/run/unifi /var/lib/mongodb

# Set permissions (tolerate missing users/dirs so a bad mount can't kill startup)
chown -R unifi:unifi /var/lib/unifi /var/log/unifi /var/run/unifi 2>/dev/null || true
chown -R mongodb:mongodb /var/lib/mongodb 2>/dev/null || true

# Graceful shutdown so `docker stop` / swarm updates stop the DB cleanly.
shutdown() {
  echo "Received stop signal — stopping services..."
  systemctl stop unifi  2>/dev/null || true
  systemctl stop mongod 2>/dev/null || true
  exit 0
}
trap shutdown SIGTERM SIGINT

# Start mongod service
echo "Starting mongod service..."
if ! systemctl start mongod; then
  echo "WARNING: mongod failed to start. If this host CPU lacks AVX support, the"
  echo "         bundled MongoDB (5.0+) will not run — deploy on an AVX-capable node."
fi
echo "Done!"

# Start unifi service
echo "Starting unifi service..."
if ! systemctl start unifi; then
  echo "WARNING: unifi service failed to start (see logs below)."
fi
echo "Done!"

# Follow UniFi logs so they show up in `docker logs` / Portainer console.
touch /var/log/unifi/server.log 2>/dev/null || true
tail -F /var/log/unifi/*.log 2>/dev/null &

# Keep the container alive regardless of the log tail; the trap handles signals.
tail -f /dev/null &
wait $!
