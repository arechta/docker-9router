#!/usr/bin/env bash
# Sync Ansh7473/9router (PR #1938 MCP Gateway) + local patches 0001-0010.
# Usage: bash scripts/sync-repository-ansh7473.sh
set -euo pipefail

export NINEROUTER_UPSTREAM_REPO="${NINEROUTER_UPSTREAM_REPO:-https://github.com/Ansh7473/9router.git}"
export NINEROUTER_UPSTREAM_REF="${NINEROUTER_UPSTREAM_REF:-master}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "${SCRIPT_DIR}/scripts/sync-repository.sh"

REPO_DIR="${SCRIPT_DIR}/repository"
if [[ ! -f "${REPO_DIR}/src/app/(dashboard)/dashboard/mcp-servers/page.js" ]]; then
  echo "ERROR: MCP Servers UI missing after sync — expected Ansh7473 fork baseline" >&2
  echo "  Check NINEROUTER_UPSTREAM_REPO and re-run with a fresh clone." >&2
  exit 1
fi

echo "OK: MCP Gateway source present (Ansh7473 + patches)"
