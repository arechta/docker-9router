#!/bin/sh
set -eu

export HOSTNAME="${NINE_ROUTER_HOSTNAME:-0.0.0.0}"
export PORT="${PORT:-20128}"

exec "$@"
