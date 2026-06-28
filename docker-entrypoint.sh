#!/bin/sh
set -eu

# Official CLI flags (--port / --host). PORT env alone does not change the listen port.
exec 9router --skip-update --no-browser \
  --port "${PORT:-20128}" \
  --host "${NINE_ROUTER_HOSTNAME:-0.0.0.0}"
