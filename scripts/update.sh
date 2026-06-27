#!/usr/bin/env bash
# Rebuild image and recreate container with minimal downtime.
# Usage: bash scripts/update.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

docker compose build --no-cache
docker compose up -d --force-recreate

echo "OK: 9router updated"
docker compose exec -T 9router sh -c '9router --help >/dev/null 2>&1; npm list -g 9router 2>/dev/null | head -1 || true'
