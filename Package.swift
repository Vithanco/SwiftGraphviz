// swift-tools-version:6.0

import PackageDescription

// Binary target selection.
//
// The SPM manifest is evaluated on the HOST, so `#if os(...)` reflects the machine
// running `swift build`, not the build *target*. That's fine for native macOS/iOS
// (xcframework) and native Linux (artifact bundle), but a WebAssembly build is a
// CROSS-compile from macOS or Linux — the host check can't detect it. Opt in
// explicitly via the GRAPHVIZ_WASM env var when cross-compiling to wasm32-wasi:
//
//   GRAPHVIZ_WASM=1 swift build --swift-sdk wasm32-unknown-wasi
//
// See WASM.md for the full workflow and CGraphvizWasm.artifactbundle build steps.
let graphvizTarget: Target
if Context.environment["GRAPHVIZ_WASM"] != nil {
    graphvizTarget = .binaryTarget(
        name: "CGraphviz",
        path: "CGraphvizWasm.artifactbundle"
    )
} else {
    #if os(Linux)
    graphvizTarget = .binaryTarget(
        name: "CGraphviz",
        path: "CGraphviz.artifactbundle"
    )
    #else
    graphvizTarget = .binaryTarget(
        name: "CGraphviz",
        path: "Graphviz.xcframework"
    )
    #endif
}

let package = Package(
    name: "SwiftGraphviz",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "SwiftGraphviz", targets: ["SwiftGraphviz"]),
    ],
    targets: [
        // Graphviz C library: xcframework on Apple, artifact bundle on Linux.
        graphvizTarget,

        // C bridge: static plugin registration (builtins.c) + unflatten algorithm.
        // Wraps Graphviz macros (ND_coord, ED_label, etc.) as C functions callable from Swift.
        .target(
            name: "GraphvizBridge",
            dependencies: ["CGraphviz"],
            path: "Sources/GraphvizBridge",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        ),

        // Swift API for Graphviz layout computation.
        .target(
            name: "SwiftGraphviz",
            dependencies: ["GraphvizBridge"],
            path: "Sources/SwiftGraphviz",
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),

        .testTarget(
            name: "SwiftGraphvizTests",
            dependencies: ["SwiftGraphviz", "GraphvizBridge"],
            path: "Tests/SwiftGraphvizTests"
        ),
    ]
)
