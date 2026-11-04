# SwiftGraphviz

A Swift package that wraps the [Graphviz](https://graphviz.org) C layout engine for macOS, iOS, Linux and WebAssembly. Build graphs in memory, run layout, and get back node positions, edge bezier points, and bounding boxes — then draw them however you like with AppKit, SwiftUI, Core Graphics, a canvas, or anything else.

The Swift layer is Foundation-free (its own `GVPoint`/`GVSize`/`GVRect`/`GVVector` geometry types) and compiles under Embedded Swift.

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
let nodeA = NodeLayout(node: a)            // .pos, .size, .rect (GVPoint/GVSize/GVRect)
let edgeLayout = try EdgeLayout(gvEdge: e) // .controlPoints, .arrowHead, .arrowTail
let graphRect = GVRect(box: gd_bb(g))

// Clean up
gvFreeLayout(gblGVContext, g)
agclose(g)
```

### Drawing an edge

`EdgeLayout.controlPoints` holds the raw cubic bezier points: a start point followed by groups of three (control 1, control 2, end). Build a path with whatever drawing API you use, e.g. Core Graphics:

```swift
import CoreGraphics

let pts = edgeLayout.controlPoints
let path = CGMutablePath()
path.move(to: pts[0].cgPoint)
for i in stride(from: 1, to: pts.count - 2, by: 3) {
    path.addCurve(to: pts[i + 2].cgPoint, control1: pts[i].cgPoint, control2: pts[i + 1].cgPoint)
}
```

On Apple platforms, `cgPoint`, `cgSize`, `cgRect` and `cgVector` convert the geometry types to Core Graphics (and `GVPoint(_: CGPoint)` etc. convert back).

## Installation

Add SwiftGraphviz to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Vithanco/swiftGraphviz.git", from: "0.3.1")
]
```

Then add `"SwiftGraphviz"` to your target's dependencies.

> **Note**: The package includes pre-built static Graphviz libraries for every platform (see [Prebuilt binaries](#prebuilt-binaries)). If you need to rebuild them from source, see [Building from Source](#building-from-source) below.

## Platforms

| Platform | Requirement | Graphviz binary |
|---|---|---|
| macOS 15+ | Swift 6.0+ | `Graphviz.xcframework` |
| iOS 18+ (device and simulator) | Swift 6.0+ | `Graphviz.xcframework` |
| Linux x86_64 | Swift 6.2+ (artifact bundles, SE-0482) | `CGraphviz.artifactbundle` |
| WebAssembly (`wasm32-unknown-wasip1`, incl. Embedded Swift) | Swift wasm SDK | `CGraphvizWasm.artifactbundle` |

Apple and Linux are picked automatically. WebAssembly is a cross-compile, so opt in with an environment variable:

```bash
GRAPHVIZ_WASM=1 swift build --swift-sdk <your wasm SDK, e.g. swift-6.3.3-RELEASE_wasm-embedded>
```

See [WASM.md](WASM.md) for the full wasm workflow and its limitations.

## What You Get

### Direct C API access

All Graphviz C functions are callable directly: `agopen`, `agnode`, `agedge`, `agset`, `agattr`, `gvLayout`, `agwrite`, etc. The C types (`Agraph_t`, `Agnode_t`, `Agedge_t`, `Agdesc_t`) are imported through the `GraphvizBridge` module.

### Type-safe Swift layer

On top of the C API, the package provides:

**Pointer extensions** for setting attributes and reading layout results:
- `GVGraph.setDefault(_:value:)`, `.set(_:_:)`, `.get(_:)`
- `GVNode.set(_:_:)`, `.pos`, `.width`, `.height`, `.size`, `.rect`
- `GVEdge.set(_:_:)`, `.getPath()` (bezier points as `[GVPoint]`), `.labelPos`, `.arrowHead`, `.arrowTail`
- `GVGraph.asString`, `.saveTo(fileName:)`, `.unflatten()`

**Layout structs** that snapshot results into safe value types:
- `NodeLayout` — position + size + bounding rect
- `EdgeLayout` — raw cubic bezier control points, arrow head/tail points, label positions
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

**Geometry types** (Foundation-free, replacing CoreGraphics):
- `GVPoint`, `GVSize`, `GVRect`, `GVVector`, built from Graphviz C structs (`GVRect(box:)`, `GVPoint(gvPoint:)`)
- `GVVector` algebra (normalize, orthogonal, rotation) and point helpers (distance, interpolation, `midPoint(between:and:)`)
- `cgPoint`/`cgSize`/`cgRect`/`cgVector` bridging where CoreGraphics is available

### Layout engines

The prebuilt libraries bundle seven Graphviz layout algorithms:

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

## What's Included in the Prebuilt Libraries

The prebuilt Graphviz libraries bundle only what's needed for layout:

- **Core**: libcgraph, libcdt, libgvc, libcommon, libpathplan
- **Layout engines**: libdotgen, libneatogen, libfdpgen, libtwopigen, libcircogen, libosage, libpatchwork
- **Layout support**: libortho, libpack, librbtree, liblabel, libvpsc, libsparse, libxdot
- **Plugins**: gvplugin_core, gvplugin_dot_layout, gvplugin_neato_layout

No external dependencies (no GLib, GTS, expat, zlib, iconv, etc.). The wasm build additionally omits VPSC, IPSEPCOLA and DIGCOLA.

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

The Linux bundle is rebuilt inside a Linux container with `./build_linux_static.sh`, and the wasm bundle with `./build_wasm_static.sh` (uses the WASI sysroot of an installed Swift wasm SDK; see [WASM.md](WASM.md)). Both accept `GRAPHVIZ_SRC` too.

## Prebuilt binaries

The three libraries in this repository are built from unmodified Graphviz release tags plus the patches below, using the scripts in the root. `artifacts.sha256` records a digest of each (file paths and contents), and `scripts/check-artifacts.sh` verifies it; SwiftPM does not, because they are local-path binary targets. To update the digests after a rebuild, run `scripts/check-artifacts.sh --update`.

| Artifact | Platforms | Graphviz | Rebuild with |
|---|---|---|---|
| `Graphviz.xcframework` | macOS, iOS, iOS Simulator | 16.1.0 | `./build_xcframework.sh` |
| `CGraphvizWasm.artifactbundle` | wasm32-wasip1 | 16.1.0 | `./build_wasm_static.sh` |
| `CGraphviz.artifactbundle` | Linux x86_64 | 16.1.0 | `./build_linux_static.sh` |

Patches applied to the Graphviz source, kept in sync across the three build scripts:

- `lib/common/labels.c`, `storeline()`: zero `span->layout` and `span->free_layout` for empty label lines (an uninitialised function pointer that crashes under wasm). See `WASM.md`.
- CMake: use `GRAPHVIZ_VERSION_*` for the version, drop the subdirectories not needed for layout (`gvpr`, `expr`, `sfio`, `ast`, `edgepaint`, `glcomp`, `mingle`, `topfish`), and disable LTO for the xcframework.
- The macOS `quartz` plugin is disabled.
- The cloned source has its `.git` removed, so `gen_version.py` reports the release version; with it, the 16.1.0 tag (a merge commit) is stamped `16.1.1~dev.<date>`.
- `signal.h` is removed from the bundled `types.h` to avoid `unsafeFlags`.
- wasm only: `-Dwith_ipsepcola=OFF -Dwith_digcola=OFF`, VPSC omitted, `wasm-toolchain.cmake` and `wasm_compat.h`.

Graphviz source for each version is at https://gitlab.com/graphviz/graphviz (tag shown above), as the Eclipse Public License asks.

## License

This repository is licensed under the [Eclipse Public License 2.0](LICENSE), the license of the Graphviz version it bundles (16.1.0; a few `lib/vpsc` files in Graphviz carry a Common Public License 1.0 header). Nothing else is vendored: no GLib, GTS, expat, zlib or iconv.
