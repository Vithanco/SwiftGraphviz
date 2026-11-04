#!/usr/bin/env bash
# bump-graphviz.sh VERSION
# Moves every place that states the bundled Graphviz version (the four build files, the
# README artifact table and licence paragraph) from the current pin to VERSION, so that
# scripts/versions.test.sh agrees with itself. It does not rebuild the binaries.
# Prints the previous version.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

new=${1:-}
[[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "usage: $0 MAJOR.MINOR.PATCH" >&2; exit 2; }

BUILD_FILES="build_xcframework.sh build_wasm_static.sh build_linux_static.sh Containerfile.build"
old=$(grep -ho -- '--branch [0-9][0-9.]*' build_linux_static.sh | awk '{print $2}' | head -1)
[ -n "$old" ] || { echo "no --branch pin in build_linux_static.sh" >&2; exit 1; }

esc() { printf '%s' "$1" | sed 's/\./\\./g'; }
o=$(esc "$old")
for f in $BUILD_FILES; do
    perl -pi -e "s/--branch $o\b/--branch $new/g" "$f"
done
for art in Graphviz.xcframework CGraphvizWasm.artifactbundle CGraphviz.artifactbundle; do
    perl -pi -e "s/^(\| \`\Q$art\E\` \|[^|]*\| )$o( \|)/\${1}$new\${2}/" README.md
done
perl -pi -e "s/bundles \($o;/bundles ($new;/" README.md

echo "$old"
