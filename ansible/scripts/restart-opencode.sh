#!/bin/bash
# restart-opencode.sh - Restart the opencode container from within
#
# This script is bind-mounted into the container at /opt/scripts/restart-opencode.sh
# The agent can call it to restart the container after installing packages or changing config.
#
# Usage (from inside the container):
#   /opt/scripts/restart-opencode.sh
#
# Or using podman directly:
#   podman restart opencode

set -e

CONTAINER_NAME="${1:-opencode}"

# Verify podman socket is available
if [ ! -S /run/podman/podman.sock ]; then
    echo "Error: Podman socket not found at /run/podman/podman.sock"
    echo "Ensure the socket is bind-mounted into the container."
    exit 1
fi

echo "Restarting container: ${CONTAINER_NAME}"
podman restart "${CONTAINER_NAME}"
echo "Container restarted successfully."
