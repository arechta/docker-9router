#!/usr/bin/env bash
# Clone or refresh decolua/9router into ./repository and apply local patches.
# Usage: bash scripts/sync-repository.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${SCRIPT_DIR}/repository"
PATCH_DIR="${SCRIPT_DIR}/patches"

UPSTREAM_URL="${NINEROUTER_UPSTREAM_REPO:-https://github.com/decolua/9router.git}"
UPSTREAM_REF="${NINEROUTER_UPSTREAM_REF:-master}"

echo "==> 9Router upstream: ${UPSTREAM_URL} @ ${UPSTREAM_REF}"

if [[ -d "${REPO_DIR}/.git" ]]; then
  echo "==> Fetching existing clone"
  git -C "${REPO_DIR}" fetch origin "${UPSTREAM_REF}" --depth 1
  git -C "${REPO_DIR}" checkout "${UPSTREAM_REF}"
  git -C "${REPO_DIR}" reset --hard "origin/${UPSTREAM_REF}"
else
  echo "==> Cloning into ${REPO_DIR}"
  git clone --depth 1 --branch "${UPSTREAM_REF}" "${UPSTREAM_URL}" "${REPO_DIR}"
fi

UPSTREAM_SHA="$(git -C "${REPO_DIR}" rev-parse --short HEAD)"
echo "==> Baseline: ${UPSTREAM_SHA}"

shopt -s nullglob
patches=("${PATCH_DIR}"/*.patch)
if ((${#patches[@]} == 0)); then
  echo "WARN: no patches in ${PATCH_DIR}"
  exit 0
fi

for patch in "${patches[@]}"; do
  echo "==> Applying $(basename "${patch}")"
  if ! git -C "${REPO_DIR}" apply --check "${patch}" 2>/dev/null; then
    echo "WARN: patch may already be applied or upstream drifted — trying anyway"
  fi
  git -C "${REPO_DIR}" apply "${patch}"
done

echo "OK: repository ready at ${REPO_DIR} (baseline ${UPSTREAM_SHA} + ${#patches[@]} patch(es))"
