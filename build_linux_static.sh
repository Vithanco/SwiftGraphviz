#!/usr/bin/env bash
#
# build_linux_static.sh
#
# Builds Graphviz from source on Linux as a static library and packages it
# as an SPM artifact bundle (SE-0482) for use with .binaryTarget().
#
# The resulting CGraphviz.artifactbundle/ is committed to the repo so that
# downstream Swift builds on Linux need zero system dependencies.
#
# Usage:
#   ./build_linux_static.sh                                              # clones graphviz
#   GRAPHVIZ_SRC=/path/to/graphviz ./build_linux_static.sh               # use local copy
#
# Prerequisites: cmake, a C compiler (gcc/clang), ar, ranlib, bison, flex, python3
#
# Counterpart of build_xcframework.sh (which targets Apple platforms).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHVIZ_SRC="${GRAPHVIZ_SRC:-}"
BUILD_ROOT="$SCRIPT_DIR/_build_linux"
OUTPUT_BUNDLE="$SCRIPT_DIR/CGraphviz.artifactbundle"
NJOBS="$(nproc)"

# Detect host architecture for the artifact bundle variant directory and triple.
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  TRIPLE="x86_64-unknown-linux-gnu";  VARIANT_DIR="linux-x86_64" ;;
    aarch64) TRIPLE="aarch64-unknown-linux-gnu";  VARIANT_DIR="linux-aarch64" ;;
    *)       echo "ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CMAKE FLAGS — must stay in sync with build_xcframework.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Layout-only, no rendering, no external dependencies.
COMMON_CMAKE_FLAGS=(
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
    -DGRAPHVIZ_CLI=OFF
    -Dwith_gvedit=OFF
    -Dwith_smyrna=OFF
    -Dwith_cxx_api=OFF
    -DENABLE_LTDL=OFF
    -DENABLE_TCL=OFF
    -DENABLE_SWIG=OFF
    -DWITH_EXPAT=OFF
    -DWITH_ZLIB=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_GTS=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_PANGOCAIRO=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_GD=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_CAIRO=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Freetype=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_GTK2=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_ANN=TRUE
)

# Libraries to merge — must stay in sync with build_xcframework.sh.
# These match what builtins.c registers (core + dot_layout + neato_layout)
# plus all their transitive dependencies.
LIB_COMPONENTS=(
    lib/cdt/libcdt.a
    lib/cgraph/libcgraph.a
    lib/gvc/libgvc.a
    lib/common/libcommon.a
    lib/pathplan/libpathplan.a
    lib/dotgen/libdotgen.a
    lib/neatogen/libneatogen.a
    lib/fdpgen/libfdpgen.a
    lib/twopigen/libtwopigen.a
    lib/circogen/libcircogen.a
    lib/osage/libosage.a
    lib/patchwork/libpatchwork.a
    lib/sparse/libsparse.a
    lib/label/liblabel.a
    lib/pack/libpack.a
    lib/ortho/libortho.a
    lib/rbtree/librbtree.a
    lib/vpsc/libvpsc.a
    lib/xdot/libxdot.a
    lib/util/libutil.a
    lib/sfdpgen/libsfdpgen.a
    plugin/core/libgvplugin_core.a
    plugin/dot_layout/libgvplugin_dot_layout.a
    plugin/neato_layout/libgvplugin_neato_layout.a
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1: Get and patch Graphviz source
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

get_graphviz_source() {
    if [ -z "$GRAPHVIZ_SRC" ]; then
        GRAPHVIZ_SRC="$SCRIPT_DIR/graphviz_src"
        if [ ! -d "$GRAPHVIZ_SRC" ]; then
            echo "Cloning Graphviz source (shallow)..."
            git clone --depth 1 https://gitlab.com/graphviz/graphviz.git "$GRAPHVIZ_SRC"
        fi
    fi

    if [ ! -f "$GRAPHVIZ_SRC/CMakeLists.txt" ]; then
        echo "ERROR: No CMakeLists.txt at $GRAPHVIZ_SRC"
        exit 1
    fi
    echo "Graphviz source: $GRAPHVIZ_SRC"
}

# Same patches as build_xcframework.sh but with GNU sed syntax.
patch_graphviz_source() {
    local lib_cmake="$GRAPHVIZ_SRC/lib/CMakeLists.txt"
    local root_cmake="$GRAPHVIZ_SRC/CMakeLists.txt"

    if grep -q 'GRAPHVIZ_VERSION_MAJOR' "$root_cmake" && \
       grep -q '# PATCHED by build_linux_static.sh' "$root_cmake" 2>/dev/null; then
        echo "Graphviz source already patched, skipping."
        return
    fi

    echo "Patching graphviz source for static Linux build..."

    # Disable subdirectories not needed for layout (some use system() which
    # complicates static linking). Skip if already done by xcframework script.
    if ! grep -q '# PATCHED by build_xcframework.sh' "$root_cmake" 2>/dev/null; then
        for lib in ast edgepaint expr glcomp gvpr mingle sfio topfish; do
            sed -i "s|^add_subdirectory($lib)|# add_subdirectory($lib)  # disabled — not needed for layout|" "$lib_cmake"
        done

        # Disable LTO — graphviz forces CMAKE_INTERPROCEDURAL_OPTIMIZATION ON
        # for Release builds, which can cause issues with static archive merging.
        sed -i 's|set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)|# set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)  # disabled for static build|' "$root_cmake"
    fi

    echo "# PATCHED by build_linux_static.sh" >> "$root_cmake"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2: Build Graphviz
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

build_graphviz() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 2: Build Graphviz (layout-only, zero external deps) ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    rm -rf "$BUILD_ROOT"
    mkdir -p "$BUILD_ROOT"

    cmake -B "$BUILD_ROOT" -S "$GRAPHVIZ_SRC" \
        -DCMAKE_BUILD_TYPE=Release \
        "${COMMON_CMAKE_FLAGS[@]}"

    cmake --build "$BUILD_ROOT" --config Release -j"$NJOBS"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3: Merge static libraries
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

merge_static_libs() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 3: Merge component .a files into libgraphviz.a      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    local merge_dir
    merge_dir="$(mktemp -d)"

    local lib_paths=()
    for component in "${LIB_COMPONENTS[@]}"; do
        local lib_path="$BUILD_ROOT/$component"
        if [ -f "$lib_path" ]; then
            lib_paths+=("$lib_path")
        else
            echo "  WARNING: $lib_path not found, skipping"
        fi
    done

    # Extract each component .a into its own subdirectory to avoid
    # .o filename collisions (e.g. multiple libs may have utils.o).
    for lib in "${lib_paths[@]}"; do
        local subdir="$merge_dir/$(basename "$lib" .a)"
        mkdir -p "$subdir"
        (cd "$subdir" && ar x "$lib")
    done

    local output="$BUILD_ROOT/libgraphviz.a"
    find "$merge_dir" -name '*.o' | sort | xargs ar rcs "$output"
    ranlib "$output"

    rm -rf "$merge_dir"

    echo "  -> libgraphviz.a: $(du -h "$output" | cut -f1)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4: Collect headers + create artifact bundle
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

collect_headers_and_bundle() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 4: Headers + artifact bundle                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    local variant="$OUTPUT_BUNDLE/$VARIANT_DIR"
    local headers="$variant/Headers"

    rm -rf "$OUTPUT_BUNDLE"
    mkdir -p "$headers"

    # Same headers as build_xcframework.sh, plus gvcint.h.
    local src_headers=(
        lib/gvc/gvc.h
        lib/gvc/gvcint.h
        lib/gvc/gvcext.h
        lib/gvc/gvcjob.h
        lib/gvc/gvcommon.h
        lib/gvc/gvplugin.h
        lib/gvc/gvconfig.h
        lib/gvc/gvcproc.h
        lib/cgraph/cgraph.h
        lib/cdt/cdt.h
        lib/common/types.h
        lib/common/color.h
        lib/common/geom.h
        lib/common/arith.h
        lib/common/textspan.h
        lib/common/usershape.h
        lib/common/render.h
        lib/common/macros.h
        lib/common/const.h
        lib/common/globals.h
        lib/common/geomprocs.h
        lib/common/colorprocs.h
        lib/common/utils.h
        lib/pathplan/pathgeom.h
        lib/pathplan/pathplan.h
    )

    for header in "${src_headers[@]}"; do
        if [ -f "$GRAPHVIZ_SRC/$header" ]; then
            cp "$GRAPHVIZ_SRC/$header" "$headers/"
        else
            echo "  WARNING: $header not found"
        fi
    done

    # config.h is generated by cmake
    if [ -f "$BUILD_ROOT/config.h" ]; then
        cp "$BUILD_ROOT/config.h" "$headers/"
    fi

    echo "Collected $(find "$headers" -name '*.h' | wc -l | tr -d ' ') headers"

    # Module map — same as the xcframework's module map
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

    # Copy the merged static library
    cp "$BUILD_ROOT/libgraphviz.a" "$variant/"

    # Extract version from graphviz source
    local gv_version
    gv_version=$(grep 'set(GRAPHVIZ_VERSION_MAJOR' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo "0")
    local gv_minor
    gv_minor=$(grep 'set(GRAPHVIZ_VERSION_MINOR' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo "0")
    local gv_patch
    gv_patch=$(grep 'set(GRAPHVIZ_VERSION_PATCH' "$GRAPHVIZ_SRC/CMakeLists.txt" | grep -o '[0-9]*' || echo "0")
    local version="${gv_version}.${gv_minor}.${gv_patch}"

    # info.json for the artifact bundle
    cat > "$OUTPUT_BUNDLE/info.json" << INFOJSON
{
    "schemaVersion": "1.0",
    "artifacts": {
        "CGraphviz": {
            "version": "${version}",
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

    echo ""
    echo "Created: $OUTPUT_BUNDLE"
    echo "  Variant: $VARIANT_DIR ($TRIPLE)"
    echo "  Library: $(du -h "$variant/libgraphviz.a" | cut -f1)"
    echo "  Version: $version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RUN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SwiftGraphviz — Linux static build                         ║"
echo "║  Layout-only Graphviz, zero external deps, artifact bundle  ║"
echo "╚══════════════════════════════════════════════════════════════╝"

get_graphviz_source       # Phase 1a: get source
patch_graphviz_source     # Phase 1b: patch
build_graphviz            # Phase 2: cmake + compile
merge_static_libs         # Phase 3: merge .a files
collect_headers_and_bundle # Phase 4: headers + artifact bundle

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  All done!                                                  ║"
echo "║                                                             ║"
echo "║  CGraphviz.artifactbundle is ready.                         ║"
echo "║  Commit it to the repo, then swift build on Linux.          ║"
echo "║                                                             ║"
echo "║  Build artifacts in _build_linux/ — rm -rf to reclaim.      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
