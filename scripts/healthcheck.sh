#!/usr/bin/env bash
# Usage: bash scripts/healthcheck.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/.env"

HOST="${NINE_ROUTER_HOST:-127.0.0.1}"
PORT="${NINE_ROUTER_PORT:-20128}"
URL="http://${HOST}:${PORT}/"

curl -sf --connect-timeout 5 "${URL}" >/dev/null
echo "OK: 9router healthy at ${URL}"
