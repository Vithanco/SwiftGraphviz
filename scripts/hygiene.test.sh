#!/usr/bin/env bash
# Two things that rot quietly: a personal path that ends up in a script, and a
# CODEOWNERS that protects nothing because a pattern has a typo or a file is not listed.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
FAILED=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $*" >&2; FAILED=1; }

# Lines 11
hits=$(git ls-files -z | xargs -0 grep -IlF '/Users/' -- 2>/dev/null | grep -v '^scripts/hygiene.test.sh$')
if [ -z "$hits" ]; then pass 'Given the repo, when tracked files are searched, then /Users/ appears nowhere'
else fail "/Users/ in: $hits"; fi

# A dependency or workflow added later is only watched if its ecosystem is listed
DEP=.github/dependabot.yml
if [ -f "$DEP" ] && grep -q 'package-ecosystem: swift' "$DEP" && grep -q 'package-ecosystem: github-actions' "$DEP"; then
    pass 'Given the repo, when Dependabot config is read, then it covers swift and github-actions'
else fail "$DEP is missing or does not list swift and github-actions"; fi

FILE=.github/CODEOWNERS
if [ ! -f "$FILE" ]; then
    fail "$FILE is missing"; exit 1
fi
patterns=$(grep -vE '^\s*(#|$)' "$FILE" | awk '{print $1}')
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
git init -q "$TMP"
matches() { printf '%s\n' "$1" > "$TMP/.git/info/exclude"; shift; printf '%s\n' "$@" | git -C "$TMP" check-ignore --no-index --stdin 2>/dev/null; }

# 13
tracked=$(git ls-files); bad=0
while read -r pat; do
    # shellcheck disable=SC2086
    [ -n "$(matches "$pat" $tracked)" ] || { fail "pattern matches no tracked file: $pat"; bad=1; }
done <<< "$patterns"
[ $bad -eq 0 ] && pass 'Given the repo, when each CODEOWNERS pattern is checked, then it matches a tracked file'

# 14
printf '%s\n' "$patterns" > "$TMP/.git/info/exclude"; bad=0
for path in Package.swift build_xcframework.sh build_linux_static.sh build_wasm_static.sh Containerfile.build \
    Graphviz.xcframework/x CGraphviz.artifactbundle/x CGraphvizWasm.artifactbundle/x CLAUDE.md .github/CODEOWNERS scripts/x.sh; do
    echo "$path" | git -C "$TMP" check-ignore --no-index -q --stdin || { fail "not covered by CODEOWNERS: $path"; bad=1; }
done
[ $bad -eq 0 ] && pass 'Given CODEOWNERS, when its patterns are read, then it covers the manifest, scripts, binaries, CLAUDE.md and .github/'

exit $FAILED
