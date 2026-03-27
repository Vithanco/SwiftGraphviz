// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.


// this package requires to build SwiftGraphviz previously via XCode in order to co

import PackageDescription


let package = Package(
    name: "MyLibrary",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"]),
    ],
    targets: [
        .binaryTarget(
            name: "MyLibrary",
            path: "./../../c/graphviz/_build/lib/cdt/Release/libcdt.a" // or use local path for .a file
        )
    ]
)
