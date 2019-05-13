// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription




let package = Package(
    name: "SwiftGraphviz",

    products: [
        .library(
            name: "SwiftGraphvizMac",
            type: .static,
            targets: ["SwiftGraphviz"]
        ),
        .library(
            name: "SwiftGraphvizMacDynamic",
            type: .dynamic,
            targets: ["SwiftGraphviz"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftGraphviz",
            dependencies: ["CGraphviz"]
        ),
        .systemLibrary(
            name: "CGraphviz",
            pkgConfig: "libgvc",    
            providers: [.brew(["Graphviz"])]
        ),
        .testTarget(
            name: "SwiftGraphvizTests",
            dependencies: ["SwiftGraphviz"]),
    ]
)
