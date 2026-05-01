#!/usr/bin/env sh
set -eu

exec bin/dlog-fixup \
  --watch \
  --log-no-change "$DLOG_NO_CHANGE" \
  --sleep "$DLOG_SLEEP" \
  --delay "$DLOG_DELAY" \
  $DLOG_EXTRA_ARGS
