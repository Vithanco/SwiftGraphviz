#!/usr/bin/env bash
#
# build_xcframework.sh
#
# Single script that:
#   1. Restructures Sources/ for pure SPM (one-time, idempotent)
#   2. Builds Graphviz from source (layout-only, zero external deps)
#   3. Packages as Graphviz.xcframework
#   4. Verifies with `swift build`
#
# Usage:
#   ./build_xcframework.sh                                          # clones graphviz
#   GRAPHVIZ_SRC=/Users/kkn/private/c/graphviz ./build_xcframework.sh  # use local copy
#
# Prerequisites: Xcode (with CLI tools), CMake (brew install cmake)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHVIZ_SRC="${GRAPHVIZ_SRC:-}"
BUILD_ROOT="$SCRIPT_DIR/_build"
OUTPUT_XCFW="$SCRIPT_DIR/Graphviz.xcframework"
HEADERS_DIR="$BUILD_ROOT/headers"
STAGING="$SCRIPT_DIR/_staging"
NJOBS="$(sysctl -n hw.ncpu)"

MACOS_DEPLOYMENT_TARGET="15.0"
IOS_DEPLOYMENT_TARGET="18.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1: Restructure Sources/ for SPM (idempotent — safe to run repeatedly)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setup_spm_structure() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 1: SPM directory structure                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    local SOURCES="$SCRIPT_DIR/Sources"
    local BRIDGE="$SOURCES/GraphvizBridge"

    # ── Create GraphvizBridge target (C sources + public headers) ──

    if [ ! -d "$BRIDGE" ]; then
        echo "Creating Sources/GraphvizBridge/..."
        mkdir -p "$BRIDGE/include"

        cp "$SOURCES/GraphvizInterface/builtins.c"  "$BRIDGE/builtins.c"
        cp "$SOURCES/GraphvizInterface/unflatten.c"  "$BRIDGE/unflatten.c"
        cp "$SOURCES/GraphvizInterface/builtins.h"   "$BRIDGE/include/builtins.h"
        cp "$SOURCES/GraphvizInterface/unflatten.h"  "$BRIDGE/include/unflatten.h"
    else
        echo "Sources/GraphvizBridge/ already exists, skipping."
    fi

    # ── Merge cocoaExtensions into SwiftGraphviz ──

    if [ -d "$SOURCES/cocoaExtensions" ]; then
        echo "Merging cocoaExtensions/ into SwiftGraphviz/Extensions/..."
        mkdir -p "$SOURCES/SwiftGraphviz/Extensions"
        for f in "$SOURCES/cocoaExtensions"/*.swift; do
            cp "$f" "$SOURCES/SwiftGraphviz/Extensions/$(basename "$f")"
        done
    fi

    # ── Move old files to _staging/ (never delete) ──

    mkdir -p "$STAGING/old_Sources" "$STAGING/old_arch_dirs" "$STAGING/old_scripts"

    # Old source directories replaced by new structure
    for old_dir in CGraphviz GraphvizInterface cocoaExtensions; do
        if [ -d "$SOURCES/$old_dir" ]; then
            mv "$SOURCES/$old_dir" "$STAGING/old_Sources/$old_dir"
            echo "  Sources/$old_dir -> _staging/"
        fi
    done

    # Old module.modulemap at Sources root
    if [ -f "$SOURCES/module.modulemap" ]; then
        mv "$SOURCES/module.modulemap" "$STAGING/old_Sources/"
    fi

    # Old bridging header (SPM doesn't use bridging headers)
    if [ -f "$SOURCES/SwiftGraphviz/SwiftGraphviz-Bridging-Header.h" ]; then
        mv "$SOURCES/SwiftGraphviz/SwiftGraphviz-Bridging-Header.h" "$STAGING/old_Sources/"
    fi

    # Old architecture-specific library directories
    for dir in macOS macOS_ARM universal; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            mv "$SCRIPT_DIR/$dir" "$STAGING/old_arch_dirs/$dir"
            echo "  $dir/ -> _staging/"
        fi
    done

    # Old build scripts (replaced by this script)
    for script in prepareLibraries.sh makeUniversal.sh makeUniversalGV.sh makeUniversalOther.sh prepareCMake.sh build_swift_graphviz.sh setup_spm.sh; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            mv "$SCRIPT_DIR/$script" "$STAGING/old_scripts/$script"
            echo "  $script -> _staging/"
        fi
    done

    echo "  Done."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2: Build Graphviz from source
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

# Libraries to merge — matches what builtins.c registers (core + dot_layout +
# neato_layout) plus all their transitive dependencies.
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

# Build a single architecture and merge component .a files into one thin lib.
build_thin() {
    local build_dir="$1"; shift
    local extra_cmake_flags=("$@")

    cmake -B "$build_dir" -S "$GRAPHVIZ_SRC" \
        -DCMAKE_BUILD_TYPE=Release \
        "${COMMON_CMAKE_FLAGS[@]}" \
        "${extra_cmake_flags[@]}"

    cmake --build "$build_dir" --config Release -j"$NJOBS"

    local lib_paths=()
    for component in "${LIB_COMPONENTS[@]}"; do
        local lib_path="$build_dir/$component"
        if [ -f "$lib_path" ]; then
            lib_paths+=("$lib_path")
        else
            echo "  WARNING: $lib_path not found, skipping"
        fi
    done

    libtool -static -o "$build_dir/libgraphviz.a" "${lib_paths[@]}" 2>&1 | grep -v 'has no symbols' || true
}

# Build for a platform, handling multi-arch by building each arch separately
# and combining with lipo (avoids the "big archive" format that xcframework
# can't read).
build_platform() {
    local platform_name="$1"; shift
    local archs="$1"; shift
    local extra_cmake_flags=("$@")
    local platform_dir="$BUILD_ROOT/$platform_name"

    echo ""
    echo "════════════════════════════════════════"
    echo "Building for: $platform_name ($archs)"
    echo "════════════════════════════════════════"

    # Split archs by semicolon
    IFS=';' read -ra arch_list <<< "$archs"

    mkdir -p "$platform_dir"

    if [ "${#arch_list[@]}" -eq 1 ]; then
        # Single arch — build directly
        build_thin "$platform_dir" \
            -DCMAKE_OSX_ARCHITECTURES="${arch_list[0]}" \
            "${extra_cmake_flags[@]}"
    else
        # Multi-arch — build each separately, then lipo
        local thin_libs=()
        for arch in "${arch_list[@]}"; do
            local arch_dir="$platform_dir/$arch"
            echo "  ── $arch ──"
            build_thin "$arch_dir" \
                -DCMAKE_OSX_ARCHITECTURES="$arch" \
                "${extra_cmake_flags[@]}"
            thin_libs+=("$arch_dir/libgraphviz.a")
        done

        lipo -create "${thin_libs[@]}" -output "$platform_dir/libgraphviz.a"
    fi

    echo "  -> $platform_name: $(du -h "$platform_dir/libgraphviz.a" | cut -f1)"
}

get_graphviz_source() {
    if [ -z "$GRAPHVIZ_SRC" ]; then
        GRAPHVIZ_SRC="$SCRIPT_DIR/graphviz_src"
        if [ ! -d "$GRAPHVIZ_SRC" ]; then
            echo "Cloning Graphviz source (shallow)..."
            git clone --depth 1 --branch 15.1.0 https://gitlab.com/graphviz/graphviz.git "$GRAPHVIZ_SRC"
        fi
    fi

    if [ ! -f "$GRAPHVIZ_SRC/CMakeLists.txt" ]; then
        echo "ERROR: No CMakeLists.txt at $GRAPHVIZ_SRC"
        exit 1
    fi
    echo "Graphviz source: $GRAPHVIZ_SRC"
}

# Patch out libraries we don't need — some (gvpr, expr) use system() which is
# unavailable on iOS. We only need the layout engine libraries.
patch_graphviz_source() {
    local lib_cmake="$GRAPHVIZ_SRC/lib/CMakeLists.txt"

    local root_cmake="$GRAPHVIZ_SRC/CMakeLists.txt"

    # Only patch once (check for our marker)
    if grep -q '# PATCHED by build_xcframework.sh' "$root_cmake" 2>/dev/null; then
        echo "Graphviz source already patched, skipping."
        return
    fi

    echo "Patching graphviz source for xcframework build..."

    # 1. Comment out subdirectories we don't need (gvpr, expr, sfio, ast,
    #    edgepaint, glcomp, mingle, sfdpgen, topfish) — some use system()
    #    which is unavailable on iOS.
    for lib in ast edgepaint expr glcomp gvpr mingle sfio topfish; do
        sed -i '' "s|^add_subdirectory($lib)|# add_subdirectory($lib)  # disabled — not needed for layout|" "$lib_cmake"
    done

    # 2. Disable LTO — graphviz forces CMAKE_INTERPROCEDURAL_OPTIMIZATION ON
    #    for Release builds (line ~801), which produces LLVM bitcode .o files
    #    that xcodebuild -create-xcframework cannot read.
    sed -i '' 's|set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)|# set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)  # disabled for xcframework|' "$root_cmake"

    # Fix a Graphviz UB bug: storeline() leaves textspan_t.free_layout/.layout
    # uninitialized for EMPTY label lines, which free_textspan() later calls via
    # a function pointer. Harmless on a zeroed native heap but a crash under wasm;
    # patched on every platform for correctness (kept in sync with build_wasm_static.sh).
    perl -0pi -e 's/(\n\s*span->just = terminator;\n)/$1\tspan->layout = NULL;\n\tspan->free_layout = NULL;\n/' \
        "$GRAPHVIZ_SRC/lib/common/labels.c"

    # Add marker so we don't patch twice
    echo "# PATCHED by build_xcframework.sh" >> "$root_cmake"
}

build_all_platforms() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 2: Build Graphviz (layout-only, zero external deps) ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    get_graphviz_source
    patch_graphviz_source

    build_platform "macos" "arm64;x86_64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOS_DEPLOYMENT_TARGET"

    build_platform "ios" "arm64" \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"

    build_platform "iossimulator" "arm64;x86_64" \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$(xcrun --sdk iphonesimulator --show-sdk-path)" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3: Collect headers + create XCFramework
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

collect_headers() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 3: Headers + XCFramework                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    rm -rf "$HEADERS_DIR"
    mkdir -p "$HEADERS_DIR"

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
            cp "$GRAPHVIZ_SRC/$header" "$HEADERS_DIR/"
        else
            echo "  WARNING: $header not found"
        fi
    done

    # config.h is generated by cmake
    if [ -f "$BUILD_ROOT/macos/config.h" ]; then
        cp "$BUILD_ROOT/macos/config.h" "$HEADERS_DIR/"
    fi

    cat > "$HEADERS_DIR/module.modulemap" << 'MODULEMAP'
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

    echo "Collected $(ls "$HEADERS_DIR"/*.h 2>/dev/null | wc -l | tr -d ' ') headers + modulemap"
}

create_xcframework() {
    rm -rf "$OUTPUT_XCFW"

    local xcfw_args=()
    for platform in macos ios iossimulator; do
        local lib="$BUILD_ROOT/$platform/libgraphviz.a"
        if [ -f "$lib" ]; then
            xcfw_args+=(-library "$lib" -headers "$HEADERS_DIR")
        fi
    done

    xcodebuild -create-xcframework \
        "${xcfw_args[@]}" \
        -output "$OUTPUT_XCFW"

    echo ""
    echo "Created: $OUTPUT_XCFW ($(du -sh "$OUTPUT_XCFW" | cut -f1))"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4: Verify
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

verify_build() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Phase 4: Verify SPM build                                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    cd "$SCRIPT_DIR"
    swift build 2>&1 | tail -5

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo ""
        echo "  swift build succeeded."
    else
        echo ""
        echo "  swift build FAILED — check errors above."
        echo "  Old files are preserved in _staging/ for recovery."
        exit 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RUN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SwiftGraphviz — full rebuild                               ║"
echo "║  Layout-only Graphviz, zero external deps, pure SPM         ║"
echo "╚══════════════════════════════════════════════════════════════╝"

setup_spm_structure     # Phase 1: restructure (idempotent)
build_all_platforms     # Phase 2: cmake + compile + merge
collect_headers         # Phase 3a: gather headers + modulemap
create_xcframework      # Phase 3b: package xcframework
verify_build            # Phase 4: swift build

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  All done!                                                  ║"
echo "║                                                             ║"
echo "║  Graphviz.xcframework is ready.                             ║"
echo "║  Package.swift is configured.                               ║"
echo "║  swift build passed.                                        ║"
echo "║                                                             ║"
echo "║  Old files preserved in _staging/ — delete when satisfied.  ║"
echo "║  Build artifacts in _build/ — rm -rf _build/ to reclaim.   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
