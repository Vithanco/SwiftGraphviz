#!/usr/bin/env bash
# The monthly upgrade workflow relies on bump-graphviz.sh leaving the repo in a state
# that versions.test.sh accepts for the pin, apart from the not-yet-rebuilt binaries.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
FAILED=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $*" >&2; FAILED=1; }

git clone -q "$ROOT" "$TMP/repo"
# Test the working tree, not HEAD: in the upgrade workflow the pin is already bumped when this runs.
cp "$ROOT"/scripts/*.sh "$TMP/repo/scripts/"
cp "$ROOT"/README.md "$ROOT"/build_xcframework.sh "$ROOT"/build_wasm_static.sh \
    "$ROOT"/build_linux_static.sh "$ROOT"/Containerfile.build "$TMP/repo/"
cd "$TMP/repo"
before=$(grep -ho -- '--branch [0-9][0-9.]*' build_linux_static.sh | awk '{print $2}')

# 1
old=$(scripts/bump-graphviz.sh 99.8.7)
if [ "$old" = "$before" ]; then pass 'Given a pinned repo, when bumped, then the previous version is printed'
else fail "printed '$old', expected '$before'"; fi

# 2
out=$(scripts/versions.test.sh 2>&1)
if [ "$(echo "$out" | grep -c '^ok ')" -eq 3 ] && echo "$out" | grep -q 'not built from 99.8.7'; then
    pass 'Given a bump, when versions.test.sh runs, then only the binaries lag the new pin'
else fail "versions.test.sh after bump: $out"; fi

# 3
if [ -z "$(git grep -n -- "--branch $before\b" -- '*.sh' Containerfile.build)" ]; then
    pass 'Given a bump, when build files are searched, then the old tag is cloned nowhere'
else fail "old tag still cloned: $(git grep -n -- "--branch $before" -- '*.sh' Containerfile.build)"; fi

# 4
if scripts/bump-graphviz.sh 16.x >/dev/null 2>&1; then fail 'accepted a malformed version'
else pass 'Given a malformed version, when bumped, then it refuses'; fi

exit $FAILED
