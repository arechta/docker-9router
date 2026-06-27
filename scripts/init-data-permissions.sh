#!/usr/bin/env bash
# One-time (and post-restore) host ownership for ./data bind mount.
# Usage: sudo bash scripts/init-data-permissions.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -o allexport
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +o allexport
fi

UID_NUM="${DOCKER_UID:-1000}"
GID_NUM="${DOCKER_GID:-1000}"

mkdir -p "${SCRIPT_DIR}/data"
chown -R "${UID_NUM}:${GID_NUM}" "${SCRIPT_DIR}/data"
chmod -R u+rwX,g+rwX "${SCRIPT_DIR}/data"

echo "OK: 9router data owned by ${UID_NUM}:${GID_NUM}"
