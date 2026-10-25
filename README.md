# SwiftGraphviz

A Swift package that wraps the [Graphviz](https://graphviz.org) C layout engine for macOS and iOS. Build graphs in memory, run layout, and get back node positions, edge paths, and bounding boxes — then draw them however you like with AppKit, SwiftUI, or Core Graphics.

This is a **layout-only** package. It does not render to images or PDF. You get coordinates; you do the drawing.

## Quick Example

```swift
import SwiftGraphviz
import GraphvizBridge

// Create a directed graph
let g = agopen("G", Agdesc_t(directed: 1, strict: 0, no_loop: 0,
                              maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0), nil)!

// Register default attributes (required before setting values on individual elements)
g.setDefault(.node(.label))
g.setDefault(.node(.width))
g.setDefault(.node(.height))

// Add nodes and an edge
let a = agnode(g, "a", 1)!
a.set(.label, "Hello")
let b = agnode(g, "b", 1)!
b.set(.label, "World")
let e = agedge(g, a, b, "e", 1)!

// Run layout
gvLayout(gblGVContext, g, GVLayoutEngine.dot.graphvizName)

// Read results
let nodeA = NodeLayout(node: a)       // .pos, .size, .rect
let edgeLayout = try EdgeLayout(gvEdge: e) // .path (CGPath), .arrowHead, .arrowTail
let graphRect = CGRect(box: gd_bb(g))

// Clean up
gvFreeLayout(gblGVContext, g)
agclose(g)
```

## Installation

Add SwiftGraphviz to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Vithanco/swiftGraphviz.git", from: "0.3.1")
]
```

Then add `"SwiftGraphviz"` to your target's dependencies.

> **Note**: The package includes a pre-built `Graphviz.xcframework` (static library). If you need to rebuild it from source, see [Building from Source](#building-from-source) below.

## Platforms

- macOS 15+
- iOS 18+

## What You Get

### Direct C API access

All Graphviz C functions are callable directly: `agopen`, `agnode`, `agedge`, `agset`, `agattr`, `gvLayout`, `agwrite`, etc. The C types (`Agraph_t`, `Agnode_t`, `Agedge_t`, `Agdesc_t`) are imported through the `GraphvizBridge` module.

### Type-safe Swift layer

On top of the C API, the package provides:

**Pointer extensions** for setting attributes and reading layout results:
- `GVGraph.setDefault(_:value:)`, `.set(_:_:)`, `.get(_:)`
- `GVNode.set(_:_:)`, `.pos`, `.width`, `.height`, `.size`, `.rect`
- `GVEdge.set(_:_:)`, `.getPath()`, `.labelPos`, `.arrowHead`, `.arrowTail`
- `GVGraph.asString`, `.saveTo(fileName:)`, `.unflatten()`

**Layout structs** that snapshot results into safe value types:
- `NodeLayout` — position + size + bounding rect
- `EdgeLayout` — CGPath from bezier splines, arrow head/tail geometry
- `ClusterLayout` — label position + bounding rect

**Enums** for type-safe Graphviz attribute names and values:
- `GVLayoutEngine` — `.dot`, `.neato`, `.fdp`, `.twopi`, `.nop`, `.nop2`
- `GVEdgeParameters`, `GVNodeParameters`, `GVGraphParameters` — attribute names
- `GVEdgeStyle` — `.curved`, `.lines`, `.polyLines`, `.orthogonal`, `.splines`
- `GVEdgeEnding` — `.none`, `.normal`, `.dot`, `.diamond`
- `GVRank`, `GVEdgeParamDir`, `GVParamValueOverlap`

**Unit types** to prevent mixing inches and screen points:
- `GVPoints` — screen points (72 per inch)
- `GVInches` — Graphviz internal unit for node dimensions

**Geometry utilities** for rendering edges:
- NSBezierPath extensions for arrow heads, circles, and diamonds
- CGVector algebra (normalize, orthogonal, rotation)
- CGPoint/CGSize/CGRect bridging from Graphviz C structs

### Layout engines

The xcframework bundles seven Graphviz layout algorithms:

| Engine | Use case |
|--------|----------|
| `dot` | Layered/hierarchical graphs (most common) |
| `neato` | Spring-model undirected graphs |
| `fdp` | Force-directed placement |
| `twopi` | Radial layout |
| `circo` | Circular layout |
| `osage` | Clustered layout |
| `patchwork` | Squarified treemap |

### Global context

The Graphviz context is initialized at module load:

```swift
// Public — use for gvLayout, gvFreeLayout, gvRender calls
public var gblGVContext: GVGlobalContextPointer

// Call once before app exit
finishGraphviz()
```

## What's Included in the XCFramework

The pre-built `Graphviz.xcframework` bundles only what's needed for layout:

- **Core**: libcgraph, libcdt, libgvc, libcommon, libpathplan
- **Layout engines**: libdotgen, libneatogen, libfdpgen, libtwopigen, libcircogen, libosage, libpatchwork
- **Layout support**: libortho, libpack, librbtree, liblabel, libvpsc, libsparse, libxdot
- **Plugins**: gvplugin_core, gvplugin_dot_layout, gvplugin_neato_layout

No external dependencies (no GLib, GTS, expat, zlib, iconv, etc.).

## Building from Source

If you need to rebuild the xcframework (e.g. to update the Graphviz version):

**Prerequisites**: Xcode (with command-line tools), CMake (`brew install cmake`)

```bash
./build_xcframework.sh
```

This clones Graphviz, builds it as a static library for macOS (arm64 + x86_64), iOS (arm64), and iOS Simulator (arm64 + x86_64), and packages the result as `Graphviz.xcframework`.

To use a local Graphviz checkout:

```bash
GRAPHVIZ_SRC=/path/to/graphviz ./build_xcframework.sh
```

## Prebuilt binaries

The three libraries in this repository are built from unmodified Graphviz release tags plus the patches below, using the scripts in the root. `artifacts.sha256` records a digest of each (file paths and contents), and `scripts/check-artifacts.sh` verifies it; SwiftPM does not, because they are local-path binary targets. To update the digests after a rebuild, run `scripts/check-artifacts.sh --update`.

| Artifact | Platforms | Graphviz | Rebuild with |
|---|---|---|---|
| `Graphviz.xcframework` | macOS, iOS, iOS Simulator | 15.1.0 | `./build_xcframework.sh` |
| `CGraphvizWasm.artifactbundle` | wasm32-wasip1 | 15.1.0 | `./build_wasm_static.sh` |
| `CGraphviz.artifactbundle` | Linux x86_64 | 14.1.6 (not yet rebuilt; `./build_linux_static.sh` and `Containerfile.build` pin 15.1.0) | `./build_linux_static.sh` |

Patches applied to the Graphviz source, kept in sync across the three build scripts:

- `lib/common/labels.c`, `storeline()`: zero `span->layout` and `span->free_layout` for empty label lines (an uninitialised function pointer that crashes under wasm). See `WASM.md`.
- CMake: use `GRAPHVIZ_VERSION_*` for the version, drop the subdirectories not needed for layout (`gvpr`, `expr`, `sfio`, `ast`, `edgepaint`, `glcomp`, `mingle`, `topfish`), and disable LTO for the xcframework.
- The macOS `quartz` plugin is disabled.
- `signal.h` is removed from the bundled `types.h` to avoid `unsafeFlags`.
- wasm only: `-Dwith_ipsepcola=OFF -Dwith_digcola=OFF`, VPSC omitted, `wasm-toolchain.cmake` and `wasm_compat.h`.

Graphviz source for each version is at https://gitlab.com/graphviz/graphviz (tag shown above), as the Eclipse Public License asks.

## License

This repository is licensed under the [Eclipse Public License 2.0](LICENSE), the license of the Graphviz version it bundles (15.1.0; a few `lib/vpsc` files in Graphviz carry a Common Public License 1.0 header). Nothing else is vendored: no GLib, GTS, expat, zlib or iconv.
