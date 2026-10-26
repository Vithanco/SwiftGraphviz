#!/usr/bin/env bash
# The bundled Graphviz version is stated in four build files, a README table, the licence
# paragraph and the binaries themselves, and the three libraries are rebuilt at different
# times. Nothing else notices when one of them lags (the Linux bundle sat on 14.1.6 while
# the scripts said 15.1.0).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
FAILED=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $*" >&2; FAILED=1; }

BUILD_FILES="build_xcframework.sh build_wasm_static.sh build_linux_static.sh Containerfile.build"
pins=$(for f in $BUILD_FILES; do grep -ho -- '--branch [0-9][0-9.]*' "$f" | sed "s|^|$f |"; done)
versions=$(echo "$pins" | awk '{print $3}' | sort -u)

# 1
if [ "$(echo "$versions" | wc -l | tr -d ' ')" -eq 1 ] && [ "$(echo "$pins" | wc -l | tr -d ' ')" -eq 4 ]; then
    pass 'Given the build files, when the cloned tag is read, then all four agree'
else fail "Graphviz tag differs between build files: $(echo "$pins" | tr '\n' ';')"; fi
want=$(echo "$versions" | head -1)

# 2
bad=""
for art in Graphviz.xcframework CGraphvizWasm.artifactbundle CGraphviz.artifactbundle; do
    shown=$(grep -F "| \`$art\`" README.md | awk -F'|' '{print $4}' | tr -d ' ')
    [ "$shown" = "$want" ] || bad+=" $art:${shown:-none}"
done
if [ -z "$bad" ]; then pass 'Given the README table, when each artifact row is read, then it states the pinned version'
else fail "README table is not at $want:$bad"; fi

# 3
bad=""
for lib in CGraphvizWasm.artifactbundle/wasm32-wasip1/libgraphviz.a CGraphviz.artifactbundle/linux-x86_64/libgraphviz.a; do
    [ -n "$(strings -a "$lib" | grep -F -m1 -- "$want")" ] || bad+=" $lib"
done
if [ -z "$bad" ]; then pass 'Given the wasm and Linux libraries, when searched, then they carry the pinned version'
else fail "not built from $want:$bad"; fi

# 4
if grep -qF "bundles ($want;" README.md; then pass 'Given the README licence paragraph, when read, then it names the pinned version'
else fail "README licence paragraph does not name $want"; fi

exit $FAILED
