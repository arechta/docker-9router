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

clone_fresh() {
  echo "==> Cloning into ${REPO_DIR}"
  rm -rf "${REPO_DIR}"
  git clone --depth 1 --branch "${UPSTREAM_REF}" "${UPSTREAM_URL}" "${REPO_DIR}"
}

if [[ -d "${REPO_DIR}/.git" ]]; then
  current_url="$(git -C "${REPO_DIR}" remote get-url origin 2>/dev/null || true)"
  if [[ "${current_url}" != "${UPSTREAM_URL}" ]]; then
    echo "==> Upstream repo changed (${current_url:-none} -> ${UPSTREAM_URL}); re-cloning"
    clone_fresh
  else
    echo "==> Fetching existing clone"
    git -C "${REPO_DIR}" fetch origin "${UPSTREAM_REF}" --depth 1
    git -C "${REPO_DIR}" checkout "${UPSTREAM_REF}"
    git -C "${REPO_DIR}" reset --hard "origin/${UPSTREAM_REF}"
    # Drop untracked files/dirs left by prior patch runs (e.g. cursorModel.js from 0001).
    git -C "${REPO_DIR}" clean -fd
  fi
else
  clone_fresh
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
  name="$(basename "${patch}")"
  echo "==> Applying ${name}"
  if git -C "${REPO_DIR}" apply --check "${patch}" 2>/dev/null; then
    git -C "${REPO_DIR}" apply "${patch}"
  elif git -C "${REPO_DIR}" apply --reverse --check "${patch}" 2>/dev/null; then
    echo "    skip: ${name} already applied"
  else
    echo "ERROR: ${name} does not apply cleanly (upstream drift?)" >&2
    exit 1
  fi
done

echo "OK: repository ready at ${REPO_DIR} (baseline ${UPSTREAM_SHA} + ${#patches[@]} patch(es))"
