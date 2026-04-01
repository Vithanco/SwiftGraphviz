// swift-tools-version:6.0

import PackageDescription

#if os(Linux)
let graphvizTarget: Target = .binaryTarget(
    name: "CGraphviz",
    path: "CGraphviz.artifactbundle"
)
#else
let graphvizTarget: Target = .binaryTarget(
    name: "CGraphviz",
    path: "Graphviz.xcframework"
)
#endif

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
            path: "Sources/SwiftGraphviz"
        ),

        .testTarget(
            name: "SwiftGraphvizTests",
            dependencies: ["SwiftGraphviz"]
        ),
    ]
)
