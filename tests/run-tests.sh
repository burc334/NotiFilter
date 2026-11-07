#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${TMPDIR:-/tmp}/notifilter-engine-tests"

clang -fobjc-arc -fblocks -Wall -Wextra \
    -I"$ROOT" \
    -I"$ROOT/prefs" \
    -o "$OUT" \
    "$ROOT/tests/NFFilterEngineTests.m" \
    "$ROOT/NFFilter.m" \
    "$ROOT/NFNotificationContext.m" \
    "$ROOT/NFDecision.m" \
    "$ROOT/NFFilterEngine.m" \
    "$ROOT/prefs/NFTransfer.m" \
    -framework Foundation

"$OUT"
