#!/usr/bin/env bash
#
# build_wasm_static.sh
#
# Builds Graphviz from source as a WebAssembly static library
# (wasm32-unknown-wasip1) and packages it as an SPM artifact bundle (SE-0482).
# Counterpart of build_linux_static.sh / build_xcframework.sh.
#
# ┌───────────────────────────────────────────────────────────────────────┐
# │ VERIFIED 2026-07-12 on macOS arm64: the full layout stack (cdt, cgraph, │
# │ gvc, common, pathplan, dotgen, neatogen, + core/dot/neato plugins)      │
# │ compiles to wasm32-wasip1 with ZERO errors and merges into a ~2.4 MB    │
# │ libgraphviz.a exporting agopen/agmemread/gvContext/gvLayout. A trivial  │
# │ malloc/stdio/setjmp/longjmp program built the same way ran under V8.    │
# └───────────────────────────────────────────────────────────────────────┘
#
# No separate wasi-sdk download is needed: the WASI sysroot ships INSIDE an
# installed Swift SDK for WebAssembly. Install one first, e.g.:
#   swift sdk install <swift-x.y.z-RELEASE_wasm bundle URL/path>
#
# Usage:
#   ./build_wasm_static.sh                              # auto-detect newest wasm SDK, clone graphviz
#   WASM_SDK_BUNDLE=/path/to/....artifactbundle ./build_wasm_static.sh
#   GRAPHVIZ_SRC=/path/to/graphviz ./build_wasm_static.sh
#
# Prerequisites: cmake, ninja, bison, flex, python3, a Swift toolchain whose
# clang/llvm-ar target wasm (swiftly's clang works), and an installed *_wasm SDK.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHVIZ_SRC="${GRAPHVIZ_SRC:-}"
BUILD_ROOT="$SCRIPT_DIR/_build_wasm"
OUTPUT_BUNDLE="$SCRIPT_DIR/CGraphvizWasm.artifactbundle"
TOOLCHAIN_FILE="$SCRIPT_DIR/wasm-toolchain.cmake"

TRIPLE="wasm32-unknown-wasip1"
VARIANT_DIR="wasm32-wasip1"

# ── Locate the WASI sysroot inside an installed Swift wasm SDK ──────────────
SDK_ROOT="${SDK_ROOT:-$HOME/Library/org.swift.swiftpm/swift-sdks}"
find_sysroot() {
    if [ -n "${WASM_SDK_BUNDLE:-}" ]; then
        find "$WASM_SDK_BUNDLE" -type d -name WASI.sdk | head -1; return
    fi
    # Newest *_wasm.artifactbundle that has a wasip1 WASI.sdk.
    find "$SDK_ROOT" -type d -name WASI.sdk -path "*wasm*wasip1*" 2>/dev/null | sort | tail -1
}
WASM_SYSROOT="$(find_sysroot)"
[ -n "$WASM_SYSROOT" ] && [ -d "$WASM_SYSROOT" ] || {
    echo "ERROR: no WASI sysroot found. Install a Swift wasm SDK (swift sdk install ...)"; exit 1; }

# Toolchain binaries: prefer swiftly's, fall back to the Swift toolchain bindir.
WASM_CLANG="${WASM_CLANG:-$(command -v clang)}"
WASM_AR="${WASM_AR:-$(command -v llvm-ar)}"
WASM_RANLIB="${WASM_RANLIB:-$(command -v llvm-ranlib)}"
# llvm-nm (BSD nm can't parse wasm objects) — prefer the one beside llvm-ar.
NM="$(dirname "$WASM_AR")/llvm-nm"; [ -x "$NM" ] || NM="$(command -v llvm-nm || echo nm)"
NJOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo "WASI sysroot : $WASM_SYSROOT"
echo "clang        : $WASM_CLANG"
echo "llvm-ar      : $WASM_AR"

# Same CMake flags as build_linux_static.sh (layout-only, no rendering, no deps).
COMMON_CMAKE_FLAGS=(
    -DBUILD_SHARED_LIBS=OFF -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
    -DGRAPHVIZ_CLI=OFF -Dwith_gvedit=OFF -Dwith_smyrna=OFF -Dwith_cxx_api=OFF
    -DENABLE_LTDL=OFF -DENABLE_TCL=OFF -DENABLE_SWIG=OFF -DWITH_EXPAT=OFF -DWITH_ZLIB=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_GTS=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_PANGOCAIRO=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_GD=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_CAIRO=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_Freetype=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_GTK2=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_ANN=TRUE
)

# wasm-only cmake flags on top of COMMON. Disable IPSEPCOLA/DIGCOLA: they pull in
# the VPSC solver, the only C++ code that throws exceptions — and the Swift wasm
# SDK's libc++abi is built without exceptions (no __cxa_throw). Dropping them keeps
# the wasm lib exception-free. Native/Linux builds keep these features.
WASM_ONLY_CMAKE_FLAGS=(
    -Dwith_ipsepcola=OFF
    -Dwith_digcola=OFF
)

# Components to merge (same as build_linux_static.sh, minus vpsc — excluded on wasm).
LIB_COMPONENTS=(cdt cgraph gvc common pathplan dotgen neatogen fdpgen twopigen
    circogen osage patchwork sparse label pack ortho rbtree xdot util sfdpgen)
PLUGIN_COMPONENTS=(core dot_layout neato_layout)

SRC_HEADERS=(
    lib/gvc/gvc.h lib/gvc/gvcint.h lib/gvc/gvcext.h lib/gvc/gvcjob.h
    lib/gvc/gvcommon.h lib/gvc/gvplugin.h lib/gvc/gvconfig.h lib/gvc/gvcproc.h
    lib/cgraph/cgraph.h lib/cdt/cdt.h
    lib/common/types.h lib/common/color.h lib/common/geom.h lib/common/arith.h
    lib/common/textspan.h lib/common/usershape.h lib/common/render.h
    lib/common/macros.h lib/common/const.h lib/common/globals.h
    lib/common/geomprocs.h lib/common/colorprocs.h lib/common/utils.h
    lib/pathplan/pathgeom.h lib/pathplan/pathplan.h
)

get_graphviz_source() {
    if [ -z "$GRAPHVIZ_SRC" ]; then
        GRAPHVIZ_SRC="$SCRIPT_DIR/graphviz_src"
        [ -d "$GRAPHVIZ_SRC" ] || git clone --depth 1 https://gitlab.com/graphviz/graphviz.git "$GRAPHVIZ_SRC"
    fi
    [ -f "$GRAPHVIZ_SRC/CMakeLists.txt" ] || { echo "ERROR: no CMakeLists.txt at $GRAPHVIZ_SRC"; exit 1; }
}

patch_graphviz_source() {
    local root="$GRAPHVIZ_SRC/CMakeLists.txt"
    grep -q '# PATCHED by build_wasm_static.sh' "$root" 2>/dev/null && return
    # Disable subdirs not needed for layout (several use system()/popen()).
    perl -0pi -e 's/^add_subdirectory\((ast|edgepaint|expr|glcomp|gvpr|mingle|sfio|topfish)\)/# $& disabled for wasm/mg' \
        "$GRAPHVIZ_SRC/lib/CMakeLists.txt"
    # Disable the macOS Quartz rendering plugin (needs Availability.h; not needed).
    perl -0pi -e 's/^add_subdirectory\(quartz\)/# add_subdirectory(quartz) disabled for wasm/mg' \
        "$GRAPHVIZ_SRC/plugin/CMakeLists.txt"
    perl -0pi -e 's/set\(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON\)/# disabled for static build/g' "$root"
    echo "# PATCHED by build_wasm_static.sh" >> "$root"
}

build_graphviz() {
    rm -rf "$BUILD_ROOT"; mkdir -p "$BUILD_ROOT"
    cmake -B "$BUILD_ROOT" -S "$GRAPHVIZ_SRC" -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DWASM_CLANG="$WASM_CLANG" -DWASM_SYSROOT="$WASM_SYSROOT" \
        -DWASM_AR="$WASM_AR" -DWASM_RANLIB="$WASM_RANLIB" \
        -DCMAKE_BUILD_TYPE=Release "${COMMON_CMAKE_FLAGS[@]}" "${WASM_ONLY_CMAKE_FLAGS[@]}"
    cmake --build "$BUILD_ROOT" -j"$NJOBS"
}

merge_static_libs() {
    local merge; merge="$(mktemp -d)"; local out="$BUILD_ROOT/libgraphviz.a"; rm -f "$out"
    local i=0
    for c in "${LIB_COMPONENTS[@]}"; do
        local a; a="$(find "$BUILD_ROOT/lib/$c" -name "lib$c.a" 2>/dev/null | head -1)"
        [ -n "$a" ] || { echo "  WARNING: lib$c.a not found"; continue; }
        local d="$merge/${c}_$i"; mkdir -p "$d"; ( cd "$d" && "$WASM_AR" x "$a" ); i=$((i+1))
    done
    for p in "${PLUGIN_COMPONENTS[@]}"; do
        local a; a="$(find "$BUILD_ROOT/plugin/$p" -name "libgvplugin_$p.a" 2>/dev/null | head -1)"
        [ -n "$a" ] || { echo "  WARNING: libgvplugin_$p.a not found"; continue; }
        local d="$merge/plug_${p}_$i"; mkdir -p "$d"; ( cd "$d" && "$WASM_AR" x "$a" ); i=$((i+1))
    done
    find "$merge" \( -name '*.obj' -o -name '*.o' \) | sort | xargs "$WASM_AR" rcs "$out"
    "$WASM_RANLIB" "$out"; rm -rf "$merge"
    echo "  -> libgraphviz.a: $(du -h "$out" | cut -f1) ($("$WASM_AR" t "$out" | wc -l | tr -d ' ') objects)"
    # grep -c (not -q): reading the whole stream avoids SIGPIPE tripping pipefail.
    [ "$("$NM" "$out" 2>/dev/null | grep -cE ' T gvLayout$' || true)" -ge 1 ] \
        || { echo "ERROR: gvLayout missing from archive"; exit 1; }
}

collect_headers_and_bundle() {
    local variant="$OUTPUT_BUNDLE/$VARIANT_DIR"; local headers="$variant/Headers"
    rm -rf "$OUTPUT_BUNDLE"; mkdir -p "$headers"
    for h in "${SRC_HEADERS[@]}"; do [ -f "$GRAPHVIZ_SRC/$h" ] && cp "$GRAPHVIZ_SRC/$h" "$headers/" || echo "  WARNING: $h not found"; done
    [ -f "$BUILD_ROOT/config.h" ] && cp "$BUILD_ROOT/config.h" "$headers/"
    cat > "$headers/module.modulemap" << 'MODULEMAP'
module CGraphviz [system] {
    header "cgraph.h"
    header "gvc.h"
    header "gvcint.h"
    header "gvcext.h"
    header "gvcjob.h"
    header "gvcommon.h"
    header "gvplugin.h"
    header "cdt.h"
    header "types.h"
    header "geom.h"
    header "arith.h"
    header "pathgeom.h"
    header "textspan.h"
    header "color.h"
    header "usershape.h"
    export *
}
MODULEMAP
    cp "$BUILD_ROOT/libgraphviz.a" "$variant/"
    local mj mn pt
    mj=$(grep 'set(GRAPHVIZ_VERSION_MAJOR' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo 0)
    mn=$(grep 'set(GRAPHVIZ_VERSION_MINOR' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo 0)
    pt=$(grep 'set(GRAPHVIZ_VERSION_PATCH' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo 0)
    cat > "$OUTPUT_BUNDLE/info.json" << INFOJSON
{
    "schemaVersion": "1.0",
    "artifacts": {
        "CGraphviz": {
            "version": "${mj}.${mn}.${pt}",
            "type": "staticLibrary",
            "variants": [
                {
                    "path": "${VARIANT_DIR}/libgraphviz.a",
                    "supportedTriples": ["${TRIPLE}"],
                    "staticLibraryMetadata": {
                        "headerPaths": ["${VARIANT_DIR}/Headers"],
                        "moduleMapPath": "${VARIANT_DIR}/Headers/module.modulemap"
                    }
                }
            ]
        }
    }
}
INFOJSON
    echo "Created $OUTPUT_BUNDLE ($TRIPLE)"
}

echo "== SwiftGraphviz — WebAssembly (wasm32-wasip1) static build =="
get_graphviz_source
patch_graphviz_source
build_graphviz
merge_static_libs
collect_headers_and_bundle
cat <<'NOTE'

== Done. ==
The FINAL wasm link (done later by SwiftPM when building VGraph) must add these
linker flags — the archive itself doesn't carry them:
  -Xlinker -lsetjmp                 (setjmp/longjmp SjLj helpers)
  -Xlinker -lwasi-emulated-signal   (signal.h emulation; pair with -D_WASI_EMULATED_SIGNAL)
and the wasm engine must enable the Exception Handling proposal (browsers do).
See WASM.md.
NOTE
