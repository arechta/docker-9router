#!/usr/bin/env bash
# Rebuild image and recreate container with minimal downtime.
# Usage: bash scripts/update.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

bash scripts/sync-repository.sh
docker compose build --no-cache
docker compose up -d --force-recreate

echo "OK: 9router updated"
docker compose ps
