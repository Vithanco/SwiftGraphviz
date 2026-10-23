#!/usr/bin/env bash
# check-artifacts.sh [ROOT]
# Every *.xcframework and *.artifactbundle in ROOT must have a line in ROOT/artifacts.sha256
# ("<digest>  <name>") and hash to it. The digest covers file paths and contents, not
# timestamps, so it survives a fresh checkout.
set -uo pipefail
ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
[ "$ROOT" = "--update" ] && ROOT=$(cd "$(dirname "$0")/.." && pwd)
SUMS=$ROOT/artifacts.sha256
FAILED=0
fail() { echo "FAIL $*" >&2; FAILED=1; }

digest() { (cd "$ROOT" && find "$1" -type f | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | cut -d' ' -f1); }

if [ "${1:-}" = "--update" ]; then
    ROOT=$(cd "$(dirname "$0")/.." && pwd); SUMS=$ROOT/artifacts.sha256; : > "$SUMS"
    for path in "$ROOT"/*.xcframework "$ROOT"/*.artifactbundle; do
        [ -d "$path" ] && echo "$(digest "$(basename "$path")")  $(basename "$path")" >> "$SUMS"
    done
    cat "$SUMS"; exit 0
fi

[ -f "$SUMS" ] || { fail "$SUMS is missing"; exit 1; }

for path in "$ROOT"/*.xcframework "$ROOT"/*.artifactbundle; do
    [ -d "$path" ] || continue
    name=$(basename "$path")
    want=$(awk -v n="$name" '$2 == n {print $1}' "$SUMS")
    if [ -z "$want" ]; then fail "no checksum recorded for $name"; continue; fi
    [ "$(digest "$name")" = "$want" ] || fail "checksum differs for $name"
done

[ $FAILED -eq 0 ] && echo "ok: all artifacts match artifacts.sha256"
exit $FAILED
