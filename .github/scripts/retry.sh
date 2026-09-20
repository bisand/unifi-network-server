#!/usr/bin/env bash
#
# Run a command, retrying it with linear backoff before giving up.
#
# Used by .github/workflows/docker-publish.yml to wrap the steps that talk to
# the network (Docker Hub, GitHub). A single flaky call there used to fail the
# whole run and leave the publish waiting for the next scheduled run, so
# anything idempotent and network-bound goes through this.
#
# Only wrap commands that are safe to run twice.
#
# Usage: retry.sh <attempts> <base-delay-seconds> -- <command> [args...]
#
# The n-th retry sleeps n * base-delay seconds.

set -uo pipefail

attempts="${1:?usage: retry.sh <attempts> <base-delay-seconds> -- <command>}"
base_delay="${2:?usage: retry.sh <attempts> <base-delay-seconds> -- <command>}"
shift 2
[ "${1:-}" = "--" ] && shift

if [ "$#" -eq 0 ]; then
  echo "retry.sh: no command given" >&2
  exit 2
fi

attempt=1
while : ; do
  "$@" && exit 0
  status=$?

  if [ "$attempt" -ge "$attempts" ]; then
    echo "::error::'$1' failed after ${attempts} attempt(s), last exit ${status}."
    exit "$status"
  fi

  delay=$(( base_delay * attempt ))
  echo "'$1' failed (attempt ${attempt}/${attempts}, exit ${status}); retrying in ${delay}s..." >&2
  sleep "$delay"
  attempt=$(( attempt + 1 ))
done
