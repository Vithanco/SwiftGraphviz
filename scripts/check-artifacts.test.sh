#!/usr/bin/env bash
# The prebuilt libraries run inside the engine, and SwiftPM does not verify them (they
# are local-path binary targets), so a recorded checksum is the only tripwire.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
CHECK="$HERE/check-artifacts.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
FAILED=0
ARTIFACTS="Graphviz.xcframework CGraphviz.artifactbundle CGraphvizWasm.artifactbundle"

digest() { (cd "$1" && find "$2" -type f | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | cut -d' ' -f1); }

fixture() {
    rm -rf "$TMP/root"; mkdir -p "$TMP/root"
    for a in $ARTIFACTS; do mkdir -p "$TMP/root/$a/lib"; echo "$a" > "$TMP/root/$a/lib/x.a"; done
    : > "$TMP/root/artifacts.sha256"
    for a in $ARTIFACTS; do echo "$(digest "$TMP/root" "$a")  $a" >> "$TMP/root/artifacts.sha256"; done
}

expect() { # name exit [words]
    local name=$1 want=$2 out code ok=1; shift 2
    out=$("$CHECK" "$TMP/root" 2>&1); code=$?
    [ "$code" -eq "$want" ] || ok=0
    for w in "$@"; do echo "$out" | grep -qF -- "$w" || ok=0; done
    if [ $ok -eq 1 ]; then echo "ok   $name"; else echo "FAIL $name (exit $code): $out" >&2; FAILED=1; fi
}

fixture
expect "Given the checksum file, when each artifact is hashed, then it matches the recorded checksum" 0

fixture; printf 'x' >> "$TMP/root/CGraphviz.artifactbundle/lib/x.a"
expect "Given an artifact altered by one byte, when checked, then the check fails and names the artifact" 1 CGraphviz.artifactbundle

fixture; grep -v CGraphvizWasm "$TMP/root/artifacts.sha256" > "$TMP/s" && mv "$TMP/s" "$TMP/root/artifacts.sha256"
expect "Given an artifact with no checksum recorded, when checked, then the check fails and names it" 1 CGraphvizWasm.artifactbundle

exit $FAILED
