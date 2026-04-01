# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
swift build          # Build the library
swift test           # Run tests (test target: SwiftGraphvizTests)
```

On macOS/iOS, the bundled `Graphviz.xcframework` is used automatically. On Linux, a pre-built static library is bundled as `CGraphviz.artifactbundle` (SE-0482, requires Swift 6.2+).

To rebuild the Linux artifact bundle (run inside a Linux container):
```bash
./build_linux_static.sh                                    # clones graphviz source
GRAPHVIZ_SRC=/path/to/graphviz ./build_linux_static.sh     # use local copy
```

To rebuild the macOS/iOS xcframework:
```bash
./build_xcframework.sh
```

Swift tools version: 6.0. Minimum platforms: macOS 15, iOS 18. Linux requires Swift 6.2+ (for artifact bundle support).

## Architecture

SwiftGraphviz is a Swift wrapper around the C Graphviz library for computing graph layouts. It has three layers:

**CGraphviz** — Platform-specific pre-built Graphviz static library. On Apple it's `Graphviz.xcframework` (macOS, iOS, simulator slices). On Linux it's `CGraphviz.artifactbundle` (SE-0482). Both are `.binaryTarget` in Package.swift.

**GraphvizBridge** (C) — Thin C bridge that wraps Graphviz macros as callable C functions, since Swift cannot invoke C macros directly. Two files:
- `builtins.c/h` — Plugin registration (`loadGraphvizLibraries()`) and accessor functions for node coords (`nd_coord`), edge splines (`ed_label`, `ed_lp`, etc.), and graph bounding boxes (`gd_bb`).
- `unflatten.c/h` — The `agUnflatten` algorithm exposed as a C function.

**SwiftGraphviz** (Swift) — Public API layer. Key types:
- `GVGraph`, `GVNode`, `GVEdge`, `GVCluster` — typealiases for `UnsafeMutablePointer<Ag*_t>` with Swift extensions for setting attributes and reading layout results.
- `GVGeometry` — Cross-platform geometry types (`GVPoint`, `GVSize`, `GVRect`, `GVVector`) replacing CoreGraphics. `GVGeometry+Apple.swift` adds `cgPoint`/`cgSize`/`cgRect`/`cgVector` bridging via `#if canImport(CoreGraphics)`.
- `NodeLayout`, `EdgeLayout`, `ClusterLayout` — Value types that snapshot layout results from the Graphviz pointers.
- `GVParameters` — Enums for Graphviz attributes (`GVNodeParameters`, `GVEdgeParameters`, `GVGraphParameters`), unit types (`GVPoints`, `GVInches`), and style/direction enums.
- `GraphvizWrapper` — Global context (`gblGVContext`), `GVLayoutEngine` enum, `GVGlobalContextPointer` typealias.

## Key Patterns

- **Static plugin registration**: Graphviz plugins (dot, neato, core) are registered statically via `gvNEWcontext` + `gvAddLibrary` on all platforms. No dynamic plugin discovery.
- **Graphviz attributes**: Set defaults on the graph first (`g.setDefault(.node(.label))`), then set values on individual elements (`node.set(.width, "1.5")`). All attributes are string-based.
- **Units**: Graphviz uses 72 points per inch. Node dimensions come back in inches from the C layer; `GVInches`/`GVPoints` types handle conversion.
- **`staging/` directory**: Contains files moved out of the main source but kept for reference. Prefer moving unused files here rather than deleting them.
