#!/bin/bash
#
# Downloads and runs Glenn R.'s UniFi Network Application installer, then verifies
# that the application actually landed in the image.
#
# The installer is interactive and exits non-zero on paths that are harmless inside
# a container, so its exit status alone is not a reliable signal. Instead of
# swallowing every failure (`|| true`, which used to let broken images get pushed),
# we treat a non-zero exit as a warning and let the verification below decide.
#
# Inputs (build args / env):
#   UNIFI_VERSION  required, e.g. 10.6.101
#   RUN_UPDATE     "true" (default) drives the installer menu via expect
set -euo pipefail

UNIFI_VERSION="${UNIFI_VERSION:?UNIFI_VERSION is required}"
RUN_UPDATE="${RUN_UPDATE:-true}"

INSTALLER="/tmp/unifi-${UNIFI_VERSION}.sh"
INSTALLER_URL="https://get.glennr.nl/unifi/install/unifi-${UNIFI_VERSION}.sh"
EXPECT_SCRIPT="/tmp/unifi_expect"

# --- Download the installer (retried; a flaky fetch must not fail the build) ---
for attempt in 1 2 3 4 5; do
  if wget --timeout=60 --tries=1 -O "$INSTALLER" "$INSTALLER_URL"; then
    break
  fi
  rm -f "$INSTALLER"
  if [ "$attempt" -eq 5 ]; then
    echo "ERROR: could not download ${INSTALLER_URL} after ${attempt} attempts." >&2
    exit 1
  fi
  echo "Installer download failed (attempt ${attempt}/5); retrying in $((attempt * 10))s..."
  sleep $((attempt * 10))
done

# A CDN error page or a 404 body would also "download" fine — make sure it is a script.
if [ ! -s "$INSTALLER" ] || ! head -n 1 "$INSTALLER" | grep -q '^#!'; then
  echo "ERROR: ${INSTALLER_URL} did not return a shell script — is ${UNIFI_VERSION} a real release?" >&2
  exit 1
fi
chmod +x "$INSTALLER"

# --- Run it ---
rc=0
if [ "$RUN_UPDATE" = "true" ]; then
  echo "RUN_UPDATE=true -> driving the installer menu (option 1) via expect"
  # 45 min ceiling per prompt so a hung installer fails the build instead of
  # burning the whole job timeout; exp_continue restarts the clock on each match.
  cat > "$EXPECT_SCRIPT" <<EOF
#!/usr/bin/expect -f
set timeout 2700
spawn ${INSTALLER} --skip --local-install
expect {
  "What would you like to perform?" { send "1\r"; exp_continue }
  timeout { puts "\nERROR: installer produced no output for 45 minutes."; exit 124 }
  eof
}
catch wait result
exit [lindex \$result 3]
EOF
  chmod +x "$EXPECT_SCRIPT"
  expect -f "$EXPECT_SCRIPT" || rc=$?
else
  echo "RUN_UPDATE is not true -> running the installer without menu automation"
  "$INSTALLER" --skip --local-install || rc=$?
fi

if [ "$rc" -ne 0 ]; then
  echo "WARNING: installer exited with status ${rc}; verifying the installation before deciding."
fi

# --- Verify (this, not the exit code, is what gates the build) ---
fail() { echo "ERROR: install verification failed — $1" >&2; exit 1; }

dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -q 'install ok installed' \
  || fail "the 'unifi' package is not installed."

INSTALLED_VERSION="$(dpkg-query -W -f='${Version}' unifi 2>/dev/null || true)"
case "$INSTALLED_VERSION" in
  "${UNIFI_VERSION}"*) : ;;
  *) fail "requested ${UNIFI_VERSION} but the installed package reports '${INSTALLED_VERSION}'." ;;
esac

[ -s /usr/lib/unifi/lib/ace.jar ] || fail "/usr/lib/unifi/lib/ace.jar is missing or empty."
command -v java   >/dev/null 2>&1 || fail "no Java runtime on PATH."
command -v mongod >/dev/null 2>&1 || fail "mongod is not installed."
[ -f /etc/init.d/unifi ] || [ -f /lib/systemd/system/unifi.service ] \
  || fail "no unifi init script or systemd unit was installed."

echo "Verified: UniFi Network Application ${INSTALLED_VERSION} installed successfully."

rm -f "$INSTALLER" "$EXPECT_SCRIPT"
