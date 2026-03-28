# SwiftGraphviz

A Swift wrapper around the [Graphviz](https://graphviz.org) layout engine, packaged as a Swift Package. Build graphs in memory and get back node/edge positions — use Graphviz as a layout engine for your app.

Supports macOS and iOS. Linux support is planned.

## Prerequisites

- Xcode (with command-line tools)
- CMake (`brew install cmake`)

## Setup

Clone the repository, then build the Graphviz xcframework from source:

```bash
./build_xcframework.sh
```

This clones Graphviz, builds it as a minimal static library (layout engines only, no rendering plugins, no external dependencies), and packages it as `Graphviz.xcframework`.

To use a local Graphviz checkout instead of cloning:

```bash
GRAPHVIZ_SRC=/path/to/graphviz ./build_xcframework.sh
```

The script also runs `swift build` to verify everything links correctly.

## Usage

Add SwiftGraphviz as a dependency in your `Package.swift` or open the directory in Xcode.

The library provides Swift access to Graphviz layout engines: dot, neato, fdp, twopi, circo, osage, and patchwork.

## What's included

The xcframework bundles only what's needed for layout computation:

- **Core**: libcgraph, libcdt, libgvc, libcommon, libpathplan
- **Layout engines**: libdotgen, libneatogen, libfdpgen, libtwopigen, libcircogen, libosage, libpatchwork
- **Layout support**: libortho, libpack, librbtree, liblabel, libvpsc, libsparse, libxdot
- **Plugins**: gvplugin_core, gvplugin_dot_layout, gvplugin_neato_layout

No external dependencies (no GLib, GTS, expat, zlib, iconv, etc.).

## License

The source code in this repository uses the Eclipse Public License 1.0, the same license as Graphviz.
